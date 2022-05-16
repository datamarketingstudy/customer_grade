# R에서 PostgreSQL 연결하기

## == Install Packages == ##
# install.packages("DBI")
# install.packages("RPostgres")

# Import Packages
library(DBI)
library(RPostgres)

# Connect posgreSQL DB
con <- dbConnect(RPostgres::Postgres(),
                 dbname = "Retail", # 본인이 설정한 DB 이름
                 port = "5432",
                 user = "postgres", # 본인 DB 계정
                 password = "2336", # 본인 DB 접속 비밀번호
                 host = "localhost")

# Table List
dbListTables(con)

# Query Execution 
query1 <- "SELECT	T.CUSTOMER_ID
		,	COUNT(DISTINCT T.TRANSACTION_ID)	AS CNT_ORDER
		,	SUM(T.TOTAL_AMT)					AS SUM_AMT
	FROM	TRANSACTIONS AS T
	LEFT OUTER JOIN
			( SELECT	TRANSACTION_ID
			  FROM		TRANSACTIONS
			  WHERE		QTY < 0
			  			)	AS X
	ON		T.TRANSACTION_ID = X.TRANSACTION_ID
	WHERE	X.TRANSACTION_ID IS NULL
	GROUP BY
			1"
df1 <- dbGetQuery(con, query1)
head(df1)
