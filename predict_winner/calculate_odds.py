import pandas as pd
from config import con


def calc_chance_scores(tabela_previsao, maps_na_ordem=None):
    team1_col = 'TEAM1'
    team2_col = 'TEAM2'

    team1 = tabela_previsao.loc[team1_col]
    team2 = tabela_previsao.loc[team2_col]

    win_maps = [
        tabela_previsao.loc[mapa.upper()] for mapa in maps_na_ordem
        ]
    lose_maps = [
        (1 - tabela_previsao.loc[mapa.upper()]) for mapa in maps_na_ordem
        ]

    chances = [
        {
            'cenario': f'{team1} 2x0 {team2}',
            'prob': win_maps[0] * win_maps[1]
        },
        {
            'cenario': f'{team1} 0x2 {team2}',
            'prob': lose_maps[0] * lose_maps[1]
        },
        {
            'cenario': f'{team1} 2x1 {team2}',
            'prob': win_maps[2] * (lose_maps[0] * win_maps[1] + win_maps[0] * lose_maps[1]) # noqa
        },
        {
            'cenario': f'{team1} 1x2 {team2}',
            'prob': lose_maps[2] * (lose_maps[0] * win_maps[1] + win_maps[0] * lose_maps[1]) # noqa
        }
    ]

    for cenario in chances:
        cenario['odd_min'] = 1/cenario['prob']

    return pd.DataFrame(chances).round(decimals=2), team1


matches_to_predict = pd.read_sql("""SELECT * FROM MATCHES_TO_PREDICT""", con)

mapas = ['Vertigo', 'Inferno', 'Ancient']

team1_col = 'TEAM1'
team2_col = 'TEAM2'

for i in matches_to_predict.index:
    tabela_previsao = matches_to_predict.iloc[i]
    chances, team1 = calc_chance_scores(tabela_previsao, mapas)

    team1win = chances[
        chances['cenario'].str.contains(team1)
        ].iloc[0]['prob']
    three_maps = chances[
        chances['cenario'].str.contains('2x1') |
        chances['cenario'].str.contains('1x2')
        ].sum()['prob']

    print(f'{team1} win: {round(100.0 * team1win, 1)}%, odd minima: {round(1/team1win, 2)}') # noqa
    print(f'{tabela_previsao.index.difference([team1_col, team2_col])[0]} win: {round(100.0 * (1-team1win), 1)}%, odd minima: {round(1/(1-team1win), 2)}') # noqa
    print(f'Over 2.5 maps: {round(100.0 * three_maps, 1)}%, odd minima: {round(1/three_maps, 2)}') # noqa
    print(chances)
