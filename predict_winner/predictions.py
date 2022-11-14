import pandas as pd
from config import con
from dataset_info import Dataset, MatchToPredict
import pickle

model_file = open("models/catb", "rb")

# Unpickle the objects

xgb = pickle.load(model_file)

model_file.close()


def column(matrix, i):
    return [row[i] for row in matrix]


def predict_match(match_to_predict, model):
    predictions = model.predict_proba(match_to_predict.X_test.drop(columns=[
        'MATCH_ID', 'MAP_NAME', 'TEAM_NAME', 'OPPONENT'
    ]))
    results = pd.DataFrame()

    # match_to_predict.X_test.to_excel('partida_prevista.xlsx', sheet_name='teste')

    results['match_id'] = list(match_to_predict.X_test['MATCH_ID'])

    results['MAP_NAME'] = list(match_to_predict.X_test['MAP_NAME'])
    results['TEAM_NAME'] = list(match_to_predict.X_test['TEAM_NAME'])
    results['OPPONENT'] = list(match_to_predict.X_test['OPPONENT'])

    results['y_pred'] = column(predictions, 1)

    return results


dataset = Dataset()
matches_to_predict = pd.read_sql('SELECT * FROM MATCHES_TO_PREDICT', con)
cursor = con.cursor()

for i in matches_to_predict.index.values.tolist():
    link = matches_to_predict.loc[i, 'HLTV_LINK']
    team1 = matches_to_predict.loc[i, 'TEAM1']
    team2 = matches_to_predict.loc[i, 'TEAM2']
    event_name = matches_to_predict.loc[i, 'EVENT_NAME']
    data = matches_to_predict.loc[i, 'DATA']
    team1rank = matches_to_predict.loc[i, 'TEAM1RANK']
    team2rank = matches_to_predict.loc[i, 'TEAM2RANK']
    maps = list()
    for num in range(1, 6):
        map_name = matches_to_predict.loc[i, 'MAP' + str(num)]
        if map_name is not None:
            maps.append(map_name)

    def ifnull(x, y):
        return y if pd.isna(x) else x

    if 'loser' in team1 or 'loser' in team2 or 'winner' in team1 or 'winner' in team2:
        continue

    try:
        previsao = predict_match(
            MatchToPredict(
                team1=team1,
                team2=team2,
                event_name=event_name,
                data=data,
                team1rank=ifnull(team1rank, 350),
                team2rank=ifnull(team2rank, 350),
                dataset_full=dataset
            ),
            model=xgb
        )
    except KeyError:
        print(f'No matches for {team1} or {team2}.')
        continue

    previsao = previsao[previsao['TEAM_NAME'] == team1]
    previsao.set_index('MAP_NAME', inplace=True)

    command = f"""
    UPDATE MATCHES_TO_PREDICT
    SET MIRAGE = {previsao.loc['Mirage', 'y_pred']},
        ANCIENT = {previsao.loc['Ancient', 'y_pred']},
        NUKE = {previsao.loc['Nuke', 'y_pred']},
        INFERNO = {previsao.loc['Inferno', 'y_pred']},
        OVERPASS = {previsao.loc['Overpass', 'y_pred']},
        VERTIGO = {previsao.loc['Vertigo', 'y_pred']},
        DUST2 = {previsao.loc['Dust2', 'y_pred']}
    WHERE HLTV_LINK = '{link}'
    """

    cursor.execute(command)

cursor.commit()
