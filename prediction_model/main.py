import pandas as pd
from xgboost import XGBClassifier, cv, DMatrix
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score, confusion_matrix, accuracy_score
from dataset_info import Dataset


def train_model(dataset_class):
    model = XGBClassifier(
        n_estimators=100,
        max_depth=2,
        min_child_weight=5,
        learning_rate=0.2,
        objective='multi:softprob',
        eval_metric='mlogloss',
        nthread=1,
        num_class=7
    )

    model.fit(dataset_class.X_train.drop(columns=['MATCH_ID']), dataset_class.y_train)
    return model


def feat_importance(modelo):
    feature_importance = modelo.get_booster().get_score(importance_type='weight')
    keys = list(feature_importance.keys())
    values = list(feature_importance.values())

    features = pd.DataFrame(data=values, index=keys, columns=["score"]).sort_values(by="score", ascending=False)
    print(features.sort_values('score', ascending=False))


def evaluate_model(modelo_treinado, dataset_class):
    predictions = modelo_treinado.predict_proba(dataset_class.X_train.drop(columns=['MATCH_ID']))
    results = pd.DataFrame(predictions, columns=dataset_class.classes)

    results['real_map'] = list(dataset_class.string_y_train)
    results['match_id'] = list(dataset_class.X_train['MATCH_ID'])

    pred = list()

    for i in results.index.values.tolist():
        for map_name in dataset_class.classes:
            if results.loc[i, 'real_map'] == map_name:
                pred.append(results.loc[i, map_name])

    results['y_pred'] = pred

    print('treino:', len(dataset_class.y_train))
    print('train', results['y_pred'].mean())

    predictions = modelo_treinado.predict_proba(dataset_class.X_test.drop(columns=['MATCH_ID']))
    results = pd.DataFrame(predictions, columns=dataset_class.classes)

    results['real_map'] = list(dataset_class.string_y_test)
    results['match_id'] = list(dataset_class.X_test['MATCH_ID'])

    pred = list()

    for i in results.index.values.tolist():
        for map_name in dataset_class.classes:
            if results.loc[i, 'real_map'] == map_name:
                pred.append(results.loc[i, map_name])

    results['y_pred'] = pred

    print('teste:', len(dataset_class.y_test))
    print('test', results['y_pred'].mean())

    results.to_excel('resultado.xlsx', sheet_name='Planilha1', index=False)


if __name__ == '__main__':
    dataset = Dataset()

    xgbc = train_model(dataset)

    feat_importance(xgbc)

    evaluate_model(xgbc, dataset)
