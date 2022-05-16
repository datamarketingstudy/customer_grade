
 -- 등급 정책 마트 테이블 생성 
 CREATE TABLE GRADE_POLICY (
 		GB			VARCHAR(200)	NOT NULL
 	,	STD_ORD		FLOAT
 	,	STD_AMT		FLOAT
 	,	GRD_CD		FLOAT			NOT NULL
 	,	GRD_NM		VARCHAR(200)	NOT NULL
 		);
 
 -- 등급 정책 데이터 INSERT
  INSERT INTO GRADE_POLICY
  VALUES
  ('case1', 4, 400000, 10, 'VIP'),
  ('case1', 2, 200000, 20, 'GOLD'),
  ('case1', 1, 		0, 30, 'SILVER'),
  ('경쟁사', 3, 300000, 10, 'VIP'),
  ('경쟁사', 2, 150000, 20, 'GOLD'),
  ('경쟁사', 1, 		0, 30, 'SILVER')  
  ;
  
   -- 참조 테이블
 	SELECT	*
 	FROM	GRADE_POLICY
 	;
 
 	SELECT	count(*)
 	FROM	CUSTOMER_GRD_HIS
 	;

  -- 등급 라벨링 쿼리
  SELECT	C.*
  FROM	(
 	SELECT	A.*
 		,	B.*
 		,	ROW_NUMBER() OVER(PARTITION BY A.CUSTOMER_ID, A.STD_YM, B.GB ORDER BY B.GRD_CD) AS RN
 	FROM	CUSTOMER_GRD_HIS AS A
 	JOIN
 			GRADE_POLICY	AS B
 	ON		A.CNT_ORDER >= B.STD_ORD
 	AND		A.SUM_AMT >= B.STD_AMT
 	ORDER BY
 			CUSTOMER_ID, STD_YM, RN
 				) AS C
  WHERE		C.RN = 1
 	;