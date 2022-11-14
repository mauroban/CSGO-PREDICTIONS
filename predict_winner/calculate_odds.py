import pandas as pd
from config import con


def calc_chance_scores(tabela_previsao, maps_na_ordem=None):
    team1 = tabela_previsao.loc['TEAM1']
    team2 = tabela_previsao.loc['TEAM2']

    win_map1 = tabela_previsao.loc[maps_na_ordem[0].upper()]

    win_map2 = tabela_previsao.loc[maps_na_ordem[1].upper()]

    win_map3 = tabela_previsao.loc[maps_na_ordem[2].upper()]

    lose_map1 = (1 - win_map1)
    lose_map2 = (1 - win_map2)
    lose_map3 = (1 - win_map3)

    chances = [
        {'cenario': f'{team1} 2x0 {team2}', 'prob': win_map1 * win_map2},
        {'cenario': f'{team1} 0x2 {team2}', 'prob': lose_map1 * lose_map2},
        {'cenario': f'{team1} 2x1 {team2}', 'prob': win_map3 * (lose_map1 * win_map2 + win_map1 * lose_map2)},
        {'cenario': f'{team1} 1x2 {team2}', 'prob': lose_map3 * (lose_map1 * win_map2 + win_map1 * lose_map2)}
    ]
    team1win = 0
    three_maps = 0

    for cenario in chances:
        cenario['odd_min'] = 1/cenario['prob']
        team1win += cenario['prob'] if cenario['cenario'] in (f'{team1} 2x0 {team2}', f'{team1} 2x1 {team2}') else 0
        three_maps += cenario['prob'] if cenario['cenario'] in (f'{team1} 2x1 {team2}', f'{team1} 1x2 {team2}') else 0

    print(f'{team1} win: {round(100.0*team1win, 1)}%, odd minima: {round(1/team1win, 2)}')
    print(f'{team2} win: {round(100.0 * (1-team1win), 1)}%, odd minima: {round(1/(1-team1win), 2)}')
    print(f'Over 2.5 maps: {round(100.0 * three_maps, 1)}%, odd minima: {round(1/three_maps, 2)}')

    return pd.DataFrame(chances).round(decimals=2)


matches_to_predict = pd.read_sql("""SELECT * FROM MATCHES_TO_PREDICT""", con)

mapas = ['Vertigo', 'Inferno', 'Ancient']

for i in matches_to_predict.index.values.tolist():
    print('\n')
    print(calc_chance_scores(matches_to_predict.iloc[i], mapas))
