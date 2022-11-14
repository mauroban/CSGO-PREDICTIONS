import pandas as pd
from xgboost import XGBClassifier
from catboost import CatBoostClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score,  accuracy_score
from dataset_info import Dataset
import pickle


def column(matrix, i):
    return [row[i] for row in matrix]


class Modelo:
    def __init__(self, algorithm, dataset_class, model_name='', save=True):

        self.dataset_class = dataset_class
        self.save = save
        self.file_name = "models/" + model_name

        self.model = algorithm
        self.model = self.train_model()

        self.results_train, self.results_test = self.get_predictions()

    def train_model(self):
        eval_set = [(self.dataset_class.X_test.drop(columns=['MATCH_ID']), self.dataset_class.y_test)]

        try:
            self.model.fit(self.dataset_class.X_train.drop(columns=['MATCH_ID']), self.dataset_class.y_train,
                           eval_set=eval_set, verbose=False)
        except TypeError:
            self.model.fit(self.dataset_class.X_train.drop(columns=['MATCH_ID']), self.dataset_class.y_train)

        if self.save:
            pickle.dump(self.model, open(self.file_name, "wb"))

        return self.model

    def get_predictions(self):

        def results_df(x, y):
            predictions = self.model.predict_proba(x.drop(columns=['MATCH_ID']))
            results = pd.DataFrame()

            results['match_id'] = list(x['MATCH_ID'])

            results['y_pred'] = column(predictions, 1)
            results['y_true'] = list(y)

            return results

        results_train = results_df(self.dataset_class.X_train, self.dataset_class.y_train)
        results_test = results_df(self.dataset_class.X_test, self.dataset_class.y_test)

        return results_train, results_test


def evaluate_model(modelos):
    results_train = modelos[0].results_train[['match_id', 'y_true']].copy()
    results_test = modelos[0].results_test[['match_id', 'y_true']].copy()
    results_train.loc[:, 'y_pred'] = 0
    results_test.loc[:, 'y_pred'] = 0

    if isinstance(modelos, list):
        for modelo in modelos:
            results_train.loc[:, 'y_pred'] = results_train.loc[:, 'y_pred'] + modelo.results_train.loc[:, 'y_pred']
            results_test.loc[:, 'y_pred'] = results_test.loc[:, 'y_pred'] + modelo.results_test.loc[:, 'y_pred']

        for df in results_train, results_test:
            df['y_pred'] = df['y_pred']/len(modelos)

            def limiar(x):
                return 1 if x >= 0.5 else 0

            df['y_limiar'] = df['y_pred'].map(limiar)

            print(len(df))
            print('auc', roc_auc_score(df['y_true'], df['y_pred']))
            print('acc', accuracy_score(df['y_true'], df['y_limiar']))

        results_test.to_excel('resultado.xlsx', sheet_name='Planilha1', index=False)

    else:
        raise TypeError('Modelo passado não é uma lista.')


def feat_importance(modelo):
    feature_importance = modelo.get_booster().get_score(importance_type='weight')
    keys = list(feature_importance.keys())
    values = list(feature_importance.values())

    features = pd.DataFrame(data=values, index=keys, columns=["score"]).sort_values(by="score", ascending=False)
    print(features.sort_values('score', ascending=False))


if __name__ == '__main__':
    dataset = Dataset()

    model = XGBClassifier(
        n_estimators=1000,
        max_depth=4,
        min_child_weight=7,
        learning_rate=0.03,
        objective='binary:logistic',
        eval_metric='logloss',
        early_stopping_rounds=15,
        nthread=1
    )

    xgb = Modelo(model, dataset, model_name='xgb')

    model = LogisticRegression(max_iter=10000)

    log_reg = Modelo(model, dataset, model_name='log_reg')

    model = CatBoostClassifier(
        iterations=1000,
        learning_rate=0.025,
        max_depth=3,
    )

    catboost = Modelo(model, dataset, model_name='catb')

    feat_importance(xgb.model)

    evaluate_model([xgb])

    evaluate_model([catboost])


