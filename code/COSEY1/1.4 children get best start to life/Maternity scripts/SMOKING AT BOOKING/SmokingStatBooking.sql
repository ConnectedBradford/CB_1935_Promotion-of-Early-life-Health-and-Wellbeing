--45,328
with cte as (
select * from 
(select  ROW_NUMBER() OVER (PARTITION BY [Hospital number], [Pregnancy number], [Estimate of due date (agreed)],Postcode ORDER BY [Hospital number] ) as Sqnce,[Date of booking], [Hospital number], [Pregnancy number], [Ethnic category], [Smoking] , coalesce( [Estimate of due date (agreed)], [Estimate of due date from LMP]) as EDD, [Gravida],Postcode
from [MedwayStaging].dbo.MedwayBooking
) ab
where [Hospital Number] is not null and Sqnce=1 
)


--45,226
,cte2 as(
select * from  
(select ROW_NUMBER() OVER (PARTITION BY [Hospital number],[Pregnancy number], [Date of booking] ORDER BY [Hospital number] ) as Sqnce2, *
from cte 
) bb
where Sqnce2 =1
)

,cte3 as(
select * from  
(select ROW_NUMBER() OVER (PARTITION BY [Hospital number],[Date of booking] ORDER BY [Hospital number] ) as Sqnce3, *
from cte2 
) bc
where Sqnce3 =1 
) 

,cte4 AS (select [Date of booking]
,[Hospital Number]
,[Pregnancy number]
,[Ethnic category] as Ethnicity
,[Smoking] 
,EDD
,Postcode
from  
(select ROW_NUMBER() OVER (PARTITION BY [Hospital number],[Pregnancy number] ORDER BY [Hospital number] ) as Sqnce4, *
from cte3
) bc
where Sqnce4 =1 and (year(EDD) > '2012' or year([Date of booking]) > '2012')
)

,cte5 as(select Date_Time_Of_Booking, HospitalNumberMother, Pregnancy_ID, Ethnic_Category,[Smoking_Status_Mother_At_Booking] , Estimated_Due_Date,Postcode
from (
SELECT ROW_NUMBER() OVER (PARTITION BY HospitalNumberMother,Pregnancy_ID ORDER BY [HospitalNumberMother] ) as Sqnce, 
       [Date_Time_Of_Booking]
      ,[HospitalNumberMother]
      ,[Pregnancy_ID]
	  ,Ethnic_Category
	  ,[Smoking_Status_Mother_At_Booking] 
      ,[Estimated_Due_Date]
	  ,Postcode
  FROM [WHMATERNITY].[dbo].[CernerAntenatalBookings]
) ab
where Sqnce=1
)

,pregnantpop as (
select * from cte4
union all
select * from cte5
)

--
,pregnantpopcount as (
select lower(Ethnicity) as Ethnicity, count(isnull(Ethnicity,0)) as EthnicCount 
from pregnantpop
group by lower(Ethnicity)
)
--9336 recruited pop
,recruitedpopcount as (
SELECT lower(Ethnicity) as Ethnicity, count(isnull(Ethnicity,0)) as EthnicCount 
FROM [BHTS-RESEARC22A].[BIB4ALLCohort].[Recruitment].[Mother]
group by lower(Ethnicity)
)
--33434
select *,

case when Smoking in ('Current smoker','Current smoker') then '1. Current Smoker'
when Smoking in('Never Smoked','Never smoked') then '2. Never Smoked'
when Smoking in ('Ex-Smoker','Ex-smoker - Stopped between conception and 12 months before conception',
'Ex-smoker - Stopped more than 12','Ex-smoker - Stopped after concep') then '3. Ex-Smoker'
when Smoking in('Unknown','Non-Smoker - History Unknown','Unknown') then '4. Unknown'

else '5. No Data'
end as smokingStatus,
case when Ethnicity = 'African'  then 'Black or African or Caribbean or Black British'
when Ethnicity = 'Any other Asian background'  then 'Asian or Asian British'
when Ethnicity = 'Any other Black background'  then 'Black or African or Caribbean or Black British'
when Ethnicity = 'Any other ethnic group'  then 'Other ethnic group'
when Ethnicity = 'Any other mixed background'  then 'Mixed multiple ethnic groups'
when Ethnicity = 'Any other White background'  then 'White'
when Ethnicity = 'Asian - Any Other Asian Background'  then 'Asian or Asian British'
when Ethnicity = 'Asian or Asian British - Bangladeshi'  then 'Asian or Asian British'
when Ethnicity = 'Asian or Asian British - Indian'  then 'Asian or Asian British'
when Ethnicity = 'Asian or Asian British - Pakistani'  then 'Asian or Asian British'
when Ethnicity = 'Bangladeshi'  then 'Asian or Asian British'
when Ethnicity = 'Black - Any Other Black Background'  then 'Black or African or Caribbean or Black British'
when Ethnicity = 'Black or Black British - African'  then 'Black or African or Caribbean or Black British'
when Ethnicity = 'Black or Black British - Caribbean'  then 'Black or African or Caribbean or Black British'
when Ethnicity = 'British'  then 'White'
when Ethnicity = 'Caribbean'  then 'Black or African or Caribbean or Black British'
when Ethnicity = 'Chinese'  then 'Asian or Asian British'
when Ethnicity = 'Indian'  then 'Asian or Asian British'
when Ethnicity = 'Irish'  then 'White'
when Ethnicity = 'Mixed - Any Other Mixed Background'  then 'Mixed multiple ethnic groups'
when Ethnicity = 'Mixed - White and Asian'  then 'Mixed multiple ethnic groups'
when Ethnicity = 'Mixed - White and Black African'  then 'Mixed multiple ethnic groups'
when Ethnicity = 'Mixed - White and Black Caribbean'  then 'Mixed multiple ethnic groups'
when Ethnicity = 'Not stated'  then 'Unknown'
when Ethnicity = 'NULL'  then 'Unknown'
when Ethnicity = 'Other - Any Other Ethnic Group'  then 'Other ethnic group'
when Ethnicity = 'Other - Chinese'  then 'Asian or Asian British'
when Ethnicity = 'Other - Not Known'  then 'Other ethnic group'
when Ethnicity = 'Other - Not Stated'  then 'Unknown'
when Ethnicity = 'Pakistani'  then 'Asian or Asian British'
when Ethnicity = 'White - Any Other White Background'  then 'White'
when Ethnicity = 'White - British'  then 'White'
when Ethnicity = 'White - Irish'  then 'White'
when Ethnicity = 'White and Asian'  then 'Mixed multiple ethnic groups'
when Ethnicity = 'White and Black African'  then 'Mixed multiple ethnic groups'
when Ethnicity = 'White and Black Caribbean'  then 'Mixed multiple ethnic groups'
end as Ethnic_Group

from pregnantpop a
--full join recruitedpopcount b
--on a.Ethnicity=b.Ethnicity collate database_default