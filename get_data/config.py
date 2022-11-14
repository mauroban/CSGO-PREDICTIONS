import pyodbc


class Connection:
    """
    Classe de conexão ao banco de dados do cartola. Originalmente é um banco de dados local.
    """
    def __init__(self):
        server = r'DESKTOP-UG66U45\SQLEXPRESS'
        database = 'CSGO-STATS'
        username = 'mauroban'
        password = 'cs123'

        self.conexao = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};'
                                      'SERVER=' + server + ';'
                                      'DATABASE=' + database + ';'
                                      'UID=' + username + ';'
                                      'PWD=' + password)


con = Connection().conexao


class MapPool:
    def __init__(self, date):
        self.date_of_change = {
            '2018-01-01': [
                'Train', 'Dust2', 'Inferno', 'Mirage', 'Nuke', 'Overpass', 'Cache'
            ],
            '2021-01-01': [
                'Train', 'Dust2', 'Inferno', 'Mirage', 'Nuke', 'Overpass', 'Vertigo'
            ],
            '2021-07-01': [
                'Ancient', 'Dust2', 'Inferno', 'Mirage', 'Nuke', 'Overpass', 'Vertigo'
            ],
        }

        self.available_maps = [
                'Ancient', 'Dust2', 'Inferno', 'Mirage', 'Nuke', 'Overpass', 'Vertigo'
            ]

        for change_date, map_pool in self.date_of_change.items():
            if date < change_date:
                self.available_maps = map_pool
                break
