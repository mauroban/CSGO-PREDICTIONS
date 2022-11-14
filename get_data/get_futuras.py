from entities import FutureMatch
from tools import get_paginas, FutureMatchTable, get_links_jogos_futuros, con

links = get_links_jogos_futuros()

cursor = con.cursor()

cursor.execute('DELETE FROM MATCHES_TO_PREDICT')
cursor.commit()


def get_match_info(links_jogos):
    return [FutureMatchTable(FutureMatch(link)) for link in links_jogos]


get_match_info(links)
