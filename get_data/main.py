from entities import Match
from tools import get_paginas, get_links_jogos, MatchTables


paginas = get_paginas('2022-11-09', '2022-11-11')

# 2022
# FALTAM JOGOS NO DIA 01/05
# FALTAM JOGOS NO DIA 18/04
# FALTAM JOGOS NO DIA 24/03
# FALTAM JOGOS DO DIA 01/01 ao dia 12/01
# FALTAM JOGOS NO DIA 23/09
# FALTAM JOGOS NO DIA 23/08
# FALTAM JOGOS NO DIA 17/08
# FALTAM JOGOS NO DIA 15/08
# FALTAM JOGOS NO DIA 19/06

# 2021
# FALTAM JOGOS NO DIA 20/10
# FALTAM JOGOS NO DIA 08/10
# FALTAM JOGOS NO DIA 03/10
# FALTAM JOGOS NO DIA 01/10


def get_match_info(link):
    try:
        return MatchTables(Match(link))
    except AttributeError:
        print(f'Erro no jogo: {link}')


for k, v in paginas.items():
    print(f'{k}...')
    jogos = get_links_jogos(v)
    for link in jogos:
        get_match_info(link)

# get_match_info(['https://www.hltv.org/matches/2359321/aurora-vs-fnatic-rising-esea-advanced-season-42-europe'])
