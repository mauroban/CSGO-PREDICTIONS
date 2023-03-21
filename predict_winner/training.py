import pandas as pd
from xgboost import XGBClassifier
from catboost import CatBoostClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.model_selection import RandomizedSearchCV
from scipy.stats import randint, uniform

from sklearn.feature_selection import SelectKBest, f_regression

from sklearn.metrics import (
    accuracy_score,
    roc_auc_score,
    average_precision_score,
    balanced_accuracy_score,
    f1_score,
    precision_score,
    recall_score,
)

from dataset_info import Dataset
import pickle


class Modelo:
    results_train: pd.DataFrame
    results_test: pd.DataFrame

    def __init__(
        self,
        algorithm,
        dataset_class,
        model_name="",
        save=True,
        tune_hyperparams=True,
    ):
        self.dataset_class = dataset_class
        self.save = save
        self.file_name = "models/" + model_name
        self.tune_hyperparams = tune_hyperparams

        self.model = algorithm
        self.model = self.train_model()

    def train_model(self):
        if self.tune_hyperparams:
            self.model = self.tune_hyperparameters()

        X_train = self.dataset_class.X_train.drop(columns=["MATCH_ID"])
        y_train = self.dataset_class.y_train

        # Feature selection
        selector = SelectKBest(f_regression, k=10)
        selector.fit(X_train, y_train)
        selected_cols = selector.get_support()
        all_cols = X_train.columns
        self.selected_cols = all_cols[selected_cols].tolist()
        X_train = X_train[self.selected_cols]

        eval_set = None
        if hasattr(self.dataset_class, 'X_val') and hasattr(self.dataset_class, 'y_val'):
            X_val = self.dataset_class.X_val.drop(columns=["MATCH_ID"])
            y_val = self.dataset_class.y_val

            # Feature selection
            X_val_selected = selector.transform(X_val)

            eval_set = [(X_val, y_val)]

        try:
            self.model.fit(
                X_train,
                y_train,
                eval_set=eval_set,
                verbose=False,
                early_stopping_rounds=10,
            )
        except AssertionError:
            self.model.fit(
                X_train,
                y_train,
            )
        except TypeError:
            self.model.fit(
                X_train,
                y_train,
            )

        if self.save:
            pickle.dump(self.model, open(self.file_name, "wb"))

        self.results_train, self.results_test = self.get_predictions()
        return self.model

    def get_predictions(self):
        def results_df(x, y):
            predictions = self.model.predict_proba(x[self.selected_cols])
            results = pd.DataFrame()

            results["match_id"] = list(x["MATCH_ID"])

            results["y_pred"] = column(predictions, 1)
            results["y_true"] = list(y)

            return results

        results_train = results_df(self.dataset_class.X_train, self.dataset_class.y_train)
        results_test = results_df(self.dataset_class.X_test, self.dataset_class.y_test)

        return results_train, results_test

    def tune_hyperparameters(self):
        n_iter = 20
        if isinstance(self.model, XGBClassifier):
            param_dist = {
                "n_estimators": randint(50, 200),
                "max_depth": randint(2, 4),
                "learning_rate": uniform(0.01, 0.1),
                "min_child_weight": randint(1, 3),
                "gamma": uniform(0, 0.5),
                "subsample": uniform(0.6, 0.8),
                "colsample_bytree": uniform(0.6, 0.8),
            }
        elif isinstance(self.model, LogisticRegression):
            param_dist = {"C": uniform(0.01, 1)}
        elif isinstance(self.model, CatBoostClassifier):
            param_dist = {
                "iterations": randint(50, 200),
                "max_depth": randint(2, 4),
                "learning_rate": uniform(0.01, 0.1),
                "l2_leaf_reg": uniform(0, 2),
                "bagging_temperature": uniform(0, 0.5),
                "random_strength": uniform(0, 0.5),
            }
        elif isinstance(self.model, SVC):
            param_dist = {
                "C": uniform(0.01, 1),
                "kernel": ["rbf"],
                "gamma": ["scale", "auto", uniform(0, 0.5)],
            }
            n_iter = 5
        else:
            raise ValueError("Invalid model type")

        random_search = RandomizedSearchCV(
            self.model,
            param_distributions=param_dist,
            cv=3,
            scoring="roc_auc",
            n_iter=n_iter,
            n_jobs=-1,
            verbose=2,
        )

        random_search.fit(
            self.dataset_class.X_train.drop(columns=["MATCH_ID"]),
            self.dataset_class.y_train,
        )

        print(f"Best parameters: {random_search.best_params_}")
        return random_search.best_estimator_


def column(matrix, i):
    return [row[i] for row in matrix]


def evaluate_model(modelos: list) -> None:
    results_train = modelos[0].results_train[["match_id", "y_true"]].copy()
    results_test = modelos[0].results_test[["match_id", "y_true"]].copy()
    results_train["y_pred"] = 0
    results_test["y_pred"] = 0

    if isinstance(modelos, list):
        for modelo in modelos:
            results_train["y_pred"] += modelo.results_train["y_pred"]
            results_test["y_pred"] += modelo.results_test["y_pred"]

        results_train["y_pred"] /= len(modelos)
        results_test["y_pred"] /= len(modelos)
    else:
        results_train["y_pred"] = modelos.results_train["y_pred"]
        results_test["y_pred"] = modelos.results_test["y_pred"]

    def print_metrics(name, y_true, y_pred):
        metrics = {
            "Accuracy": accuracy_score(y_true, round(y_pred)),
            "Precision": precision_score(y_true, round(y_pred)),
            "Recall": recall_score(y_true, round(y_pred)),
            "F1 score": f1_score(y_true, round(y_pred)),
            "ROC AUC score": roc_auc_score(y_true, y_pred),
            "Average precision score": average_precision_score(y_true, y_pred),
            "Balanced accuracy score": balanced_accuracy_score(y_true, round(y_pred))
        }
        print(f"{name} results:")
        for metric_name, metric_value in metrics.items():
            print(f"{metric_name}: {metric_value:.3f}", end=" | ")
        print()

    print_metrics("Train", results_train["y_true"], results_train["y_pred"])
    print_metrics("Test", results_test["y_true"], results_test["y_pred"])


def feat_importance(modelo):
    try:
        feature_importance = modelo.feature_importances_
    except AttributeError:
        try:
            feature_importance = modelo.coef_[0]
        except AttributeError:
            print("Error: Model does not have a feature_importances_ or coef_ attribute.")
            return

    keys = list(modelo.feature_names_in_)
    values = list(feature_importance)

    features = pd.DataFrame(data=values, index=keys, columns=["score"]).sort_values(by="score", ascending=False)
    print(features)


if __name__ == '__main__':
    dataset = Dataset()

    model = XGBClassifier()

    xgb = Modelo(model, dataset, model_name='xgb')

    model = LogisticRegression()

    log_reg = Modelo(model, dataset, model_name='log_reg')

    model = CatBoostClassifier()

    catboost = Modelo(model, dataset, model_name='catb')

    # model = SVC(probability=True)
    #
    # svc = Modelo(model, dataset, model_name='svm')

    feat_importance(xgb.model)

    evaluate_model([xgb])

    evaluate_model([catboost])

    evaluate_model([log_reg])

    # evaluate_model([svc])

    evaluate_model([catboost, log_reg, xgb])
