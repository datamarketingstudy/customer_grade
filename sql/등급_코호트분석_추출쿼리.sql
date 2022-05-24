
  /* 등급 코호트 분석 추출 쿼리 */

/*	실습시 최초 1회 실행 (주석 제거 후 실행)
  CREATE TABLE CUST_GRD_HIS_COHORT AS (
 WITH TBL AS(
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
 	AND		B.GB = 'case2'
 	ORDER BY
 			CUSTOMER_ID, STD_YM, RN
 				) AS C
  WHERE		C.RN = 1 )
  	SELECT	*
  	FROM	TBL
  	)  	
  	; */
  
  	-- 참조 테이블 		
  	SELECT	*
  	FROM	CUST_GRD_HIS_COHORT
  	;

  	-- 1단계. 고객마다 각 등급의 코호트(최초 등급 부여일자)를 구함
  	SELECT	C.CUSTOMER_ID
  		,	C.GRD_CD
  		,	C.GRD_NM
  		,	MIN(TO_DATE(C.STD_YM, 'YYYY-MM-DD'))	AS FST_DT
  	FROM	CUST_GRD_HIS_COHORT	AS C
  	GROUP BY
  			1, 2, 3
  	ORDER BY
  			1
  			;
  		
  	-- 2단계. 각 등급 코호트 기준일자와 이후 등급 유지(상승 포함) 월 간격 구하기	
  	SELECT	C.CUSTOMER_ID
  		,	C.GRD_CD
  		,	C.GRD_NM
  		,	MIN(TO_DATE(C.STD_YM, 'YYYY-MM-DD'))	AS FST_DT
  		,	G.GRD_CD	AS AFT_GRD_CD
  		,	G.GRD_NM	AS AFT_GRD_NM
  		,	TO_DATE(G.STD_YM, 'YYYY-MM-DD')	AS AFT_DT
  		,	EXTRACT(MONS FROM 
  					AGE(TO_DATE(G.STD_YM, 'YYYY-MM-DD'),
  						MIN(TO_DATE(C.STD_YM, 'YYYY-MM-DD'))))	AS DIFF_MONS
  	FROM	CUST_GRD_HIS_COHORT	AS C
  	JOIN
  			(	SELECT	*
  				FROM	CUST_GRD_HIS_COHORT )	AS G
  	ON		C.CUSTOMER_ID = G.CUSTOMER_ID
  	AND		G.GRD_CD <= C.GRD_CD	-- 최상위 등급일수록 등급 코드 숫자는 작아짐
  	AND		G.STD_YM >= C.STD_YM	-- 등급 기준월로부터 이후의 등급월만 조인되게 제한
  	GROUP BY
  			1, 2, 3, 5, 6, 7
  	ORDER BY
  			1;
  		
  	-- 3단계. 코호트 집계
 WITH	COHORT_COUNT AS (	
  	SELECT	C.CUSTOMER_ID
  		,	C.GRD_CD
  		,	C.GRD_NM
  		,	MIN(TO_DATE(C.STD_YM, 'YYYY-MM-DD'))	AS FST_DT
  		,	G.GRD_CD	AS AFT_GRD_CD
  		,	G.GRD_NM	AS AFT_GRD_NM
  		,	TO_DATE(G.STD_YM, 'YYYY-MM-DD')	AS AFT_DT
  		,	EXTRACT(MONS FROM 
  					AGE(TO_DATE(G.STD_YM, 'YYYY-MM-DD'),
  						MIN(TO_DATE(C.STD_YM, 'YYYY-MM-DD'))))	AS DIFF_MONS
  	FROM	CUST_GRD_HIS_COHORT	AS C
  	JOIN
  			(	SELECT	*
  				FROM	CUST_GRD_HIS_COHORT )	AS G
  	ON		C.CUSTOMER_ID = G.CUSTOMER_ID
  	AND		G.GRD_CD <= C.GRD_CD	-- 최상위 등급일수록 등급 코드 숫자는 작아짐
  	AND		G.STD_YM >= C.STD_YM	-- 등급 기준월로부터 이후의 등급월만 조인되게 제한
  	GROUP BY
  			1, 2, 3, 5, 6, 7
  				)
  	SELECT	CC.FST_DT
  		,	CC.DIFF_MONS
  		,	COUNT(DISTINCT CC.CUSTOMER_ID)	AS CNT_CUST
  	FROM	COHORT_COUNT AS CC
  	WHERE	1 = 1
  	AND		CC.GRD_NM = 'GOLD'	-- 원하는 등급 필터
  	GROUP BY
  			1, 2
  	ORDER BY
  			1, 2;
  		
  		
  	
  	