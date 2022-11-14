CREATE TABLE EVENT (
ID INT PRIMARY KEY,
NAME VARCHAR(255),
HLTV_LINK VARCHAR(512),
);


CREATE TABLE MATCH (
ID INT PRIMARY KEY,
HLTV_LINK VARCHAR(512),
EVENT_ID INT,
DATE_UNIX BIGINT,
EVENT_DATE DATE,
MAX_GAMES INT
);


ALTER TABLE MATCH
ADD CONSTRAINT FK_MATCH_EVENT
FOREIGN KEY (EVENT_ID) REFERENCES EVENT(ID);


CREATE TABLE PICK_ACTION (
MATCH_ID INT NOT NULL,
PICK_ORDER INT NOT NULL,
RAW_TEXT VARCHAR(255),
TYPE VARCHAR(100),
AUTHOR VARCHAR(100),
MAP VARCHAR(100)
);

ALTER TABLE PICK_ACTION
ADD CONSTRAINT PK_PICK_ACTION PRIMARY KEY (MATCH_ID, PICK_ORDER);


ALTER TABLE PICK_ACTION
ADD CONSTRAINT FK_PICK_ACTION_MATCH
FOREIGN KEY (MATCH_ID) REFERENCES MATCH(ID);


CREATE TABLE AVAILABLE_MAP (
MATCH_ID INT NOT NULL,
PICK_ORDER INT NOT NULL,
MAP_NAME VARCHAR(100) NOT NULL
);

ALTER TABLE AVAILABLE_MAP
ADD CONSTRAINT PK_AVAILABLE_MAP PRIMARY KEY (MATCH_ID, PICK_ORDER, MAP_NAME);

ALTER TABLE AVAILABLE_MAP
ADD CONSTRAINT FK_AVAILABLE_MAP_MATCH
FOREIGN KEY (MATCH_ID) REFERENCES MATCH(ID);



CREATE TABLE GAME (
MATCH_ID INT NOT NULL,
GAME_NUM INT NOT NULL,
MAP_NAME VARCHAR(100),
TEAM1 VARCHAR(100),
TEAM2 VARCHAR(100),
WINNER VARCHAR(100),
OT INT
);

ALTER TABLE GAME
ADD CONSTRAINT PK_GAME PRIMARY KEY (MATCH_ID, GAME_NUM);

ALTER TABLE GAME
ADD CONSTRAINT FK_GAME_MATCH
FOREIGN KEY (MATCH_ID) REFERENCES MATCH(ID);



CREATE TABLE TEAM_GAME (
MATCH_ID INT NOT NULL,
GAME_NUM INT NOT NULL,
NAME VARCHAR(100) NOT NULL,
RANK INT,
SCORE INT,
START_SIDE VARCHAR(50),
SCORE_CT INT,
SCORE_T INT
);

ALTER TABLE TEAM_GAME
ADD CONSTRAINT PK_TEAM_GAME PRIMARY KEY (MATCH_ID, GAME_NUM, NAME);

ALTER TABLE TEAM_GAME
ADD CONSTRAINT FK_TEAM_GAME_MATCH
FOREIGN KEY (MATCH_ID) REFERENCES MATCH(ID);



CREATE TABLE PLAYER_GAME (
MATCH_ID INT NOT NULL,
GAME_NUM INT NOT NULL,
TEAM_NAME VARCHAR(100) NOT NULL,
NAME VARCHAR(100) NOT NULL,
KILLS INT,
DEATHS INT,
ADR DECIMAL(5, 2),
RATING DECIMAL(4, 2),
KAST DECIMAL(5, 2),
CT_KILLS INT,
CT_DEATHS INT,
CT_ADR DECIMAL(5, 2),
CT_RATING DECIMAL(4, 2),
CT_KAST DECIMAL(5, 2),
T_DEATHS INT,
T_ADR DECIMAL(5, 2),
T_RATING DECIMAL(4, 2),
T_KILLS INT,
T_KAST DECIMAL(5, 2),
);

ALTER TABLE PLAYER_GAME
ADD CONSTRAINT PK_PLAYER_GAME PRIMARY KEY (MATCH_ID, GAME_NUM, TEAM_NAME, NAME);

ALTER TABLE PLAYER_GAME
ADD CONSTRAINT FK_PLAYER_GAME_MATCH
FOREIGN KEY (MATCH_ID) REFERENCES MATCH(ID);