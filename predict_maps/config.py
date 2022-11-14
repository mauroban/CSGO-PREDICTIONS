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
