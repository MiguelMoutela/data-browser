#!/bin/bash

# Runs achilles queries to populate count db for cloudsql in BigQuery
set -xeuo pipefail
IFS=$'\n\t'

USAGE="./generate-clousql-cdr/run-achilles-queries.sh --bq-project <PROJECT> --bq-dataset <DATASET> --workbench-project <PROJECT>"
USAGE="$USAGE --cdr-version=YYYYMMDD"

while [ $# -gt 0 ]; do
  echo "1 is $1"
  case "$1" in
    --bq-project) BQ_PROJECT=$2; shift 2;;
    --bq-dataset) BQ_DATASET=$2; shift 2;;
    --workbench-project) WORKBENCH_PROJECT=$2; shift 2;;
    --workbench-dataset) WORKBENCH_DATASET=$2; shift 2;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

if [ -z "${BQ_PROJECT}" ]
then
  echo "Usage: $USAGE"
  exit 1
fi

if [ -z "${BQ_DATASET}" ]
then
  echo "Usage: $USAGE"
  exit 1
fi

if [ -z "${WORKBENCH_PROJECT}" ]
then
  echo "Usage: $USAGE"
  exit 1
fi

if [ -z "${WORKBENCH_DATASET}" ]
then
  echo "Usage: $USAGE"
  exit 1
fi

#Get the list of tables in the dataset
tables=$(bq --project=$BQ_PROJECT --dataset=$BQ_DATASET ls)

# Next Populate achilles_results
echo "Running achilles queries..."


echo "Getting person count"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, count_value,source_count_value) select 0 as id, 1 as analysis_id,  COUNT(distinct person_id) as count_value, 0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\`"


# Gender count
echo "Getting gender count"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\` (id, analysis_id, stratum_1, count_value,source_count_value)
select 0, 2 as analysis_id,  cast (gender_concept_id as STRING) as stratum_1, COUNT(distinct person_id) as count_value, 0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\`
group by GENDER_CONCEPT_ID"

# Age count
# 3	Number of persons by year of birth
echo "Getting age count"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\` (id, analysis_id, stratum_1, count_value,source_count_value)
select 0, 3 as analysis_id,  CAST(year_of_birth AS STRING) as stratum_1, COUNT(distinct person_id) as count_value, 0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\`
group by YEAR_OF_BIRTH"


#  4	Number of persons by race
echo "Getting race count"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\` (id, analysis_id, stratum_1, count_value,source_count_value)
select 0, 4 as analysis_id,  CAST(RACE_CONCEPT_ID AS STRING) as stratum_1, COUNT(distinct person_id) as count_value,0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\`
group by RACE_CONCEPT_ID"

# 5	Number of persons by ethnicity
echo "Getting ethnicity count"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\` (id, analysis_id, stratum_1, count_value,source_count_value)
select 0, 5 as analysis_id,  CAST(ETHNICITY_CONCEPT_ID AS STRING) as stratum_1, COUNT(distinct person_id) as count_value, 0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\`
group by ETHNICITY_CONCEPT_ID"

# 6	Number of persons by age decile 18-29
echo "Getting age decile count"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\` (id, analysis_id, stratum_1, count_value,source_count_value)
select 0, 6 as analysis_id,  '2' as stratum_2,
COUNT(distinct person_id) as count_value, 0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\`
where (2019 - year_of_birth) >= 18 and (2019 - year_of_birth) < 30
group by stratum_2"

# 6	Number of persons by age decile 30-89
echo "Getting age decile count"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\` (id, analysis_id, stratum_1, count_value,source_count_value)
select 0, 6 as analysis_id,  CAST(floor((2019 - year_of_birth)/10) AS STRING) as stratum_2,
COUNT(distinct person_id) as count_value, 0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\`
where floor((2019 - year_of_birth)/10) >=3 and floor((2019 - year_of_birth)/10) < 9
group by stratum_2"

# 6	Number of persons by age decile 90+
echo "Getting age decile count"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\` (id, analysis_id, stratum_1, count_value,source_count_value)
select 0, 6 as analysis_id,  CAST(floor((2019 - year_of_birth)/10) AS STRING) as stratum_2,
COUNT(distinct person_id) as count_value, 0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\`
where floor((2019 - year_of_birth)/10) >=9
group by stratum_2"

# 7 Gender identity count
echo "Getting gender identity count"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\` (id, analysis_id, stratum_1, stratum_2, count_value,source_count_value)
select 0, 7 as analysis_id, CAST(ob.value_source_concept_id as STRING) as stratum_1, c.concept_name as stratum_2, count(distinct p.person_id) as count_value, 0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob on p.person_id=ob.person_id
join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on c.concept_id=ob.value_source_concept_id
where ob.observation_source_concept_id=1585838
group by ob.value_source_concept_id, c.concept_name"

# 8 Getting race/ ethnicity counts from ppi data (Answers to gender/ ethnicity question in survey)
echo "Getting race ethnicity counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\` (id, analysis_id, stratum_1, stratum_2, count_value,source_count_value)
select 0, 8 as analysis_id, CAST(ob.value_source_concept_id as STRING) as stratum_1, c.concept_name as stratum_2, count(distinct p.person_id) as count_value, 0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob on p.person_id=ob.person_id
join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on c.concept_id=ob.value_source_concept_id
where ob.observation_source_concept_id=1586140
group by ob.value_source_concept_id, c.concept_name"

# 10	Number of all persons by year of birth and by gender
echo "Getting year of birth , gender count"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, count_value,source_count_value)
select 0, 10 as analysis_id,  CAST(year_of_birth AS STRING) as stratum_1,
  CAST(gender_concept_id AS STRING) as stratum_2,
  COUNT(distinct person_id) as count_value, 0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\`
group by YEAR_OF_BIRTH, gender_concept_id"

# 12	Number of persons by race and ethnicity
echo "Getting race, ethnicity count"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, count_value,source_count_value)
select 0, 12 as analysis_id, CAST(RACE_CONCEPT_ID AS STRING) as stratum_1, CAST(ETHNICITY_CONCEPT_ID AS STRING) as stratum_2, COUNT(distinct person_id) as count_value,
0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\`
group by RACE_CONCEPT_ID,ETHNICITY_CONCEPT_ID"

# 200	(3000 ) Number of persons with at least one visit occurrence, by visit_concept_id
echo "Getting visit count and source count"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_3, count_value, source_count_value)
select 0 as id,3000 as analysis_id,CAST(vo1.visit_concept_id AS STRING) as stratum_1,'Visit' as stratum_3,
COUNT(distinct vo1.PERSON_ID) as count_value,(select COUNT(distinct vo2.person_id) from
\`${BQ_PROJECT}.${BQ_DATASET}.visit_occurrence\` vo2 where vo2.visit_source_concept_id=vo1.visit_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.visit_occurrence\` vo1
where vo1.visit_concept_id > 0
group by vo1.visit_concept_id
union all
select 0 as id,3000 as analysis_id,CAST(vo1.visit_source_concept_id AS STRING) as stratum_1,'Visit' as stratum_3,
COUNT(distinct vo1.PERSON_ID) as count_value,COUNT(distinct vo1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.visit_occurrence\` vo1
where vo1.visit_source_concept_id not in (select distinct visit_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.visit_occurrence\`)
group by vo1.visit_source_concept_id"


# 400 (3000)	Number of persons with at least one condition occurrence, by condition_concept_id
# There was weird data in combined20181025 that has rows in condition occurrence table with concept id 19 which was causing problem while fetching domain participant count
# so added check in there (Remove after checking the data is proper)
echo "Querying condition_occurrence ..."
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_3, count_value, source_count_value)
select 0, 3000 as analysis_id,
CAST(co1.condition_CONCEPT_ID AS STRING) as stratum_1,'Condition' as stratum_3,
COUNT(distinct co1.PERSON_ID) as count_value, (select COUNT(distinct co2.person_id) from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co2
where co2.condition_source_concept_id=co1.condition_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
where co1.condition_concept_id > 0 and co1.condition_concept_id != 19
group by co1.condition_CONCEPT_ID
union all
select 0 as id,3000 as analysis_id,CAST(co1.condition_source_concept_id AS STRING) as stratum_1,'Condition' as stratum_3,
COUNT(distinct co1.PERSON_ID) as count_value,COUNT(distinct co1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
where co1.condition_source_concept_id not in (select distinct condition_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\`)
and co1.condition_source_concept_id != 19
group by co1.condition_source_concept_id"

# Condition gender
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3101 as analysis_id,
CAST(co1.condition_concept_id AS STRING) as stratum_1,
CAST(p1.gender_concept_id AS STRING) as stratum_2,'Condition' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co2
on p2.person_id=co2.person_id where co2.condition_source_concept_id=co1.condition_concept_id and p2.gender_concept_id = p1.gender_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
on p1.person_id = co1.person_id
where co1.condition_concept_id > 0
group by co1.condition_concept_id, p1.gender_concept_id
union all
select 0, 3101 as analysis_id,CAST(co1.condition_source_concept_id AS STRING) as stratum_1,CAST(p1.gender_concept_id AS STRING) as stratum_2,
'Condition' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value from
\`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
on p1.person_id = co1.person_id
where co1.condition_source_concept_id not in (select distinct condition_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\`)
group by co1.condition_source_concept_id, p1.gender_concept_id"

# Condition gender identity
# Calculating the gender identity counts for condition concepts based on the answer of each person to ppi question 1585838
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3107 as analysis_id,
CAST(co1.condition_concept_id AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Condition' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
(select COUNT(distinct ob.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob
on ob.person_id=co2.person_id
where co2.condition_source_concept_id=co1.condition_concept_id and ob.observation_source_concept_id=1585838
and ob.value_source_concept_id = ob1.value_source_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on co1.person_id = ob1.person_id
where co1.condition_concept_id > 0 and ob1.observation_source_concept_id=1585838
group by co1.condition_concept_id, ob1.value_source_concept_id
union all
select 0, 3107 as analysis_id,CAST(co1.condition_source_concept_id AS STRING) as stratum_1,CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Condition' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,COUNT(distinct ob1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1 on ob1.person_id = co1.person_id
where co1.condition_source_concept_id not in (select distinct condition_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\`)
and ob1.observation_source_concept_id=1585838
group by co1.condition_source_concept_id, ob1.value_source_concept_id"

# Condition race ethnicity analysis
# Calculating the race-ethnicity counts for condition concepts based on the answer of each person to ppi question 1586140
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3108 as analysis_id,
CAST(co1.condition_concept_id AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Condition' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
(select COUNT(distinct ob.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob
on ob.person_id=co2.person_id
where co2.condition_source_concept_id=co1.condition_concept_id and ob.observation_source_concept_id=1586140
and ob.value_source_concept_id = ob1.value_source_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on co1.person_id = ob1.person_id
where co1.condition_concept_id > 0 and ob1.observation_source_concept_id=1586140
group by co1.condition_concept_id, ob1.value_source_concept_id
union all
select 0, 3108 as analysis_id,CAST(co1.condition_source_concept_id AS STRING) as stratum_1,CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Condition' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,COUNT(distinct ob1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1 on ob1.person_id = co1.person_id
where co1.condition_source_concept_id not in (select distinct condition_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\`)
and ob1.observation_source_concept_id=1586140
group by co1.condition_source_concept_id, ob1.value_source_concept_id"

# (400 age ) 3102 Number of persons with at least one condition occurrence, by condition_concept_id by age decile
# Age Deciles : They will be  18-29 , 30-39, 40-49, 50-59, 60-69, 70-79, 80-89, 90+
#  children are 0-17 and we don't have children for now .
#Ex yob = 2000  , start date : 2017 -- , sd - yob = 17  / 10 = 1.7 floor(1.7 ) = 1
# 30 - 39 , 2017 - 1980 = 37 / 10 = 3

# Get the 30-39, 40 - 49 , ... groups
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
 (id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3102 as analysis_id,
CAST(co1.condition_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from condition_start_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Condition' as stratum_3,
count(distinct p1.person_id) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co2
on p2.person_id=co2.person_id where co2.condition_source_concept_id=co1.condition_concept_id and floor((extract(year from co2.condition_start_date) - p2.year_of_birth)/10) >=3 and floor((extract(year from co2.condition_start_date) - p2.year_of_birth)/10) < 9) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
on p1.person_id = co1.person_id
where floor((extract(year from condition_start_date) - p1.year_of_birth)/10) >=3 and floor((extract(year from condition_start_date) - p1.year_of_birth)/10) < 9
and co1.condition_concept_id > 0
group by co1.condition_concept_id, stratum_2
union all
select 0, 3102 as analysis_id,
CAST(co1.condition_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from condition_start_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Condition' as stratum_3,
COUNT(distinct p1.person_id) as count_value,
COUNT(distinct p1.person_id) as source_count_value from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
on p1.person_id = co1.person_id where floor((extract(year from condition_start_date) - p1.year_of_birth)/10) >=3 and floor((extract(year from condition_start_date) - p1.year_of_birth)/10) < 9
and co1.condition_concept_id != co1.condition_source_concept_id
group by co1.condition_source_concept_id, stratum_2"

#Get conditions by age decile id 3102 for the 18-29 group labeled as 2
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value,source_count_value)
select 0, 3102 as analysis_id,
CAST(co1.condition_concept_id AS STRING) as stratum_1,
'2' as stratum_2,'Condition' as stratum_3,
 count(distinct p1.person_id) as count_value,(select COUNT(distinct p2.PERSON_ID) from
 \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co2 on
 p2.person_id=co2.person_id where co2.condition_source_concept_id=co1.condition_concept_id
 and (extract(year from co2.condition_start_date) - p2.year_of_birth) > 18 and
 (extract(year from co2.condition_start_date) - p2.year_of_birth) < 30) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
on p1.person_id = co1.person_id
where (extract(year from condition_start_date) - p1.year_of_birth) > 18 and (extract(year from condition_start_date) - p1.year_of_birth) < 30
and co1.condition_concept_id > 0
group by co1.condition_concept_id, stratum_2
union all
select 0, 3102 as analysis_id,CAST(co1.condition_source_concept_id AS STRING) as stratum_1,'2' as stratum_2,'Condition' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value from
\`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
on p1.person_id = co1.person_id
where (extract(year from condition_start_date) - p1.year_of_birth) > 18
and (extract(year from condition_start_date) - p1.year_of_birth) < 30
and co1.condition_concept_id != co1.condition_source_concept_id
group by co1.condition_source_concept_id,stratum_2"

# Get the 90+ condition age decile counts
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
 (id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3102 as analysis_id,
CAST(co1.condition_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from condition_start_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Condition' as stratum_3,
count(distinct p1.person_id) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co2
on p2.person_id=co2.person_id where co2.condition_source_concept_id=co1.condition_concept_id and floor((extract(year from co2.condition_start_date) - p2.year_of_birth)/10) >=9) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
on p1.person_id = co1.person_id
where floor((extract(year from condition_start_date) - p1.year_of_birth)/10) >=9
and co1.condition_concept_id > 0
group by co1.condition_concept_id, stratum_2
union all
select 0, 3102 as analysis_id,
CAST(co1.condition_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from condition_start_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Condition' as stratum_3,
COUNT(distinct p1.person_id) as count_value,
COUNT(distinct p1.person_id) as source_count_value from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
on p1.person_id = co1.person_id where floor((extract(year from condition_start_date) - p1.year_of_birth)/10) >=9
and co1.condition_concept_id != co1.condition_source_concept_id
group by co1.condition_source_concept_id, stratum_2"


# Get the 30-39, 40 - 49 , ... groups
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
 (id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3106 as analysis_id,
CAST(co1.condition_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Condition' as stratum_3,
count(distinct p1.person_id) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co2
on p2.person_id=co2.person_id where co2.condition_source_concept_id=co1.condition_concept_id and floor((extract(year from current_date()) - p2.year_of_birth)/10) >=3 and floor((extract(year from current_date()) - p2.year_of_birth)/10) < 9) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
on p1.person_id = co1.person_id
where floor((extract(year from current_date()) - p1.year_of_birth)/10) >=3 and floor((extract(year from current_date()) - p1.year_of_birth)/10) < 9
and co1.condition_concept_id > 0
group by co1.condition_concept_id, stratum_2
union all
select 0, 3106 as analysis_id,
CAST(co1.condition_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Condition' as stratum_3,
COUNT(distinct p1.person_id) as count_value,
COUNT(distinct p1.person_id) as source_count_value from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
on p1.person_id = co1.person_id where floor((extract(year from current_date()) - p1.year_of_birth)/10) >=3 and floor((extract(year from current_date()) - p1.year_of_birth)/10) < 9
and co1.condition_concept_id != co1.condition_source_concept_id
group by co1.condition_source_concept_id, stratum_2"

# 90+
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
 (id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3106 as analysis_id,
CAST(co1.condition_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Condition' as stratum_3,
count(distinct p1.person_id) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co2
on p2.person_id=co2.person_id where co2.condition_source_concept_id=co1.condition_concept_id and floor((extract(year from current_date()) - p2.year_of_birth)/10) >=9) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
on p1.person_id = co1.person_id
where floor((extract(year from current_date()) - p1.year_of_birth)/10) >=9
and co1.condition_concept_id > 0
group by co1.condition_concept_id, stratum_2
union all
select 0, 3106 as analysis_id,
CAST(co1.condition_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Condition' as stratum_3,
COUNT(distinct p1.person_id) as count_value,
COUNT(distinct p1.person_id) as source_count_value from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
on p1.person_id = co1.person_id where floor((extract(year from current_date()) - p1.year_of_birth)/10) >=9
and co1.condition_concept_id != co1.condition_source_concept_id
group by co1.condition_source_concept_id, stratum_2"

#Get conditions by age decile id 3106 for the 18-29 group labeled as 2
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value,source_count_value)
select 0, 3106 as analysis_id,
CAST(co1.condition_concept_id AS STRING) as stratum_1,
'2' as stratum_2,'Condition' as stratum_3,
count(distinct p1.person_id) as count_value,(select COUNT(distinct p2.PERSON_ID) from
\`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co2 on p2.person_id=co2.person_id
where co2.condition_source_concept_id=co1.condition_concept_id
and (extract(year from current_date()) - p2.year_of_birth) > 18 and
(extract(year from current_date()) - p2.year_of_birth) < 30) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
on p1.person_id = co1.person_id
where (extract(year from current_date()) - p1.year_of_birth) > 18 and (extract(year from current_date()) - p1.year_of_birth) < 30
and co1.condition_concept_id > 0
group by co1.condition_concept_id, stratum_2
union all
select 0, 3106 as analysis_id,CAST(co1.condition_source_concept_id AS STRING) as stratum_1,'2' as stratum_2,'Condition' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co1
on p1.person_id = co1.person_id
where (extract(year from current_date()) - p1.year_of_birth) > 18 and (extract(year from current_date()) - p1.year_of_birth) < 30
and co1.condition_concept_id != co1.condition_source_concept_id
group by co1.condition_source_concept_id,stratum_2"

# No death data now per Kayla. Later when we have more data
# 500	(3000) Number of persons with death, by cause_concept_id
#echo "Querying death ..."
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
#(id, analysis_id, stratum_1, count_value)
#select 0, 3000 as analysis_id,
#	CAST(d1.cause_concept_id AS STRING) as stratum_1,
#	COUNT(distinct d1.PERSON_ID) as count_value
#from \`${BQ_PROJECT}.${BQ_DATASET}.death\` d1
#group by d1.cause_concept_id"
#
## Death (3101)	Number of persons with a death by death cause concept id by  gender concept id
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
#(id, analysis_id, stratum_1, stratum_2, count_value)
#select 0, 3101 as analysis_id,
#	CAST(co1.cause_concept_id AS STRING) as stratum_1,
#	CAST(p1.gender_concept_id AS STRING) as stratum_2,
#	COUNT(distinct p1.PERSON_ID) as count_value
#from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
#\`${BQ_PROJECT}.${BQ_DATASET}.death\` co1
#on p1.person_id = co1.person_id
#group by co1.cause_concept_id,
#	p1.gender_concept_id"
#
## Death (3102)	Number of persons with a death by death cause concept id by  age decile  30+ yr old deciles */
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
#(id, analysis_id, stratum_1, stratum_2, count_value)
#select 0, 3102 as analysis_id,
#	CAST(co1.cause_concept_id AS STRING) as stratum_1,
#	CAST(floor((extract(year from co1.death_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,
#	COUNT(distinct p1.PERSON_ID) as count_value
#from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
#\`${BQ_PROJECT}.${BQ_DATASET}.death\` co1
#on p1.person_id = co1.person_id
#where floor((extract(year from co1.death_date) - p1.year_of_birth)/10) >=2
#group by co1.cause_concept_id,
#	stratum_2"
#
## Death (3102)	Number of persons with a death by death cause concept id by  age decile  <20 yr old decile 1 */
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
#(id, analysis_id, stratum_1, stratum_2, count_value)
#select 0, 3102 as analysis_id, CAST(co1.cause_concept_id AS STRING) as stratum_1, '2' as stratum_2,
#	COUNT(distinct p1.PERSON_ID) as count_value
#from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
#\`${BQ_PROJECT}.${BQ_DATASET}.death\` co1
#on p1.person_id = co1.person_id
#where (extract(year from co1.death_date) - p1.year_of_birth) < 20
#group by co1.cause_concept_id,
#	stratum_2"

# 600	Number of persons with at least one procedure occurrence, by procedure_concept_id
echo "Querying procedure_occurrence"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_3, count_value, source_count_value)
select 0, 3000 as analysis_id,
CAST(po1.procedure_CONCEPT_ID AS STRING) as stratum_1,'Procedure' as stratum_3,
COUNT(distinct po1.PERSON_ID) as count_value,
(select COUNT(distinct po2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` po2 where po2.procedure_source_CONCEPT_ID=po1.procedure_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` po1
where po1.procedure_concept_id > 0
group by po1.procedure_CONCEPT_ID
union all
select 0, 3000 as analysis_id,CAST(po1.procedure_source_CONCEPT_ID AS STRING) as stratum_1,'Procedure' as stratum_3,
COUNT(distinct po1.PERSON_ID) as count_value,
COUNT(distinct po1.PERSON_ID) as source_count_value from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` po1 where
po1.procedure_source_CONCEPT_ID not in (select distinct procedure_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\`)
group by po1.procedure_source_CONCEPT_ID"

#  600 Gender
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3101 as analysis_id,
CAST(co1.procedure_CONCEPT_ID AS STRING) as stratum_1,
CAST(p1.gender_concept_id AS STRING) as stratum_2,'Procedure' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co2
on p2.person_id = co2.person_id where co2.procedure_source_concept_id=co1.procedure_concept_id and p2.gender_concept_id=p1.gender_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1
on p1.person_id = co1.person_id
where co1.procedure_concept_id > 0
group by co1.procedure_concept_id,
p1.gender_concept_id
union all
select 0, 3101 as analysis_id,CAST(co1.procedure_source_CONCEPT_ID AS STRING) as stratum_1,
CAST(p1.gender_concept_id AS STRING) as stratum_2,'Procedure' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1
on p1.person_id = co1.person_id
where co1.procedure_source_concept_id not in (select distinct procedure_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\`)
group by co1.procedure_source_concept_id,p1.gender_concept_id"

#  3107 Gender identity
# Calculates gender identity counts for procedure concepts based on the people' answer to ppi question 1585838
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3107 as analysis_id,
CAST(co1.procedure_CONCEPT_ID AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Procedure' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
(select COUNT(distinct ob2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob2 on ob2.person_id=co2.person_id
where co2.procedure_source_concept_id=co1.procedure_concept_id and ob2.observation_source_concept_id=1585838 and
ob2.value_source_concept_id = ob1.value_source_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1 on ob1.person_id = co1.person_id
where co1.procedure_concept_id > 0 and ob1.observation_source_concept_id=1585838
group by co1.procedure_concept_id,
ob1.value_source_concept_id
union all
select 0, 3107 as analysis_id,CAST(co1.procedure_source_CONCEPT_ID AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Procedure' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
COUNT(distinct ob1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on ob1.person_id = co1.person_id
where co1.procedure_source_concept_id not in (select distinct procedure_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\`)
and ob1.observation_source_concept_id=1585838
group by co1.procedure_source_concept_id,ob1.value_source_concept_id"

#  3108 race ethnicity identity
# Calculates race ethnicity counts for procedure concepts based on the people' answer to ppi question 1586140
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3108 as analysis_id,
CAST(co1.procedure_CONCEPT_ID AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Procedure' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
(select COUNT(distinct ob2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob2 on ob2.person_id=co2.person_id
where co2.procedure_source_concept_id=co1.procedure_concept_id and ob2.observation_source_concept_id=1586140 and
ob2.value_source_concept_id = ob1.value_source_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1 on ob1.person_id = co1.person_id
where co1.procedure_concept_id > 0 and ob1.observation_source_concept_id=1586140
group by co1.procedure_concept_id,
ob1.value_source_concept_id
union all
select 0, 3108 as analysis_id,CAST(co1.procedure_source_CONCEPT_ID AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Procedure' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
COUNT(distinct ob1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on ob1.person_id = co1.person_id
where co1.procedure_source_concept_id not in (select distinct procedure_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\`)
and ob1.observation_source_concept_id=1586140
group by co1.procedure_source_concept_id,ob1.value_source_concept_id"


# 600 age
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value,source_count_value)
select 0, 3102 as analysis_id,
CAST(co1.procedure_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.procedure_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Procedure' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co2
on p2.person_id = co2.person_id where co2.procedure_source_concept_id=co1.procedure_concept_id
and floor((extract(year from co2.procedure_date) - p2.year_of_birth)/10) >=3 and floor((extract(year from co2.procedure_date) - p2.year_of_birth)/10) <9) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1
on p1.person_id = co1.person_id
where floor((extract(year from co1.procedure_date) - p1.year_of_birth)/10) >=3 and floor((extract(year from co1.procedure_date) - p1.year_of_birth)/10) <9
and co1.procedure_concept_id > 0
group by co1.procedure_concept_id, stratum_2
union all
select 0, 3102 as analysis_id,CAST(co1.procedure_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.procedure_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Procedure' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1
on p1.person_id = co1.person_id
where (floor((extract(year from co1.procedure_date) - p1.year_of_birth)/10) >=3 and floor((extract(year from co1.procedure_date) - p1.year_of_birth)/10) <9)
and co1.procedure_concept_id != co1.procedure_source_concept_id
group by co1.procedure_source_concept_id, stratum_2"

# 600 age 90+
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value,source_count_value)
select 0, 3102 as analysis_id,
CAST(co1.procedure_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.procedure_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Procedure' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co2
on p2.person_id = co2.person_id where co2.procedure_source_concept_id=co1.procedure_concept_id
and floor((extract(year from co2.procedure_date) - p2.year_of_birth)/10) >=9) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1
on p1.person_id = co1.person_id
where floor((extract(year from co1.procedure_date) - p1.year_of_birth)/10) >=9
and co1.procedure_concept_id > 0
group by co1.procedure_concept_id, stratum_2
union all
select 0, 3102 as analysis_id,CAST(co1.procedure_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.procedure_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Procedure' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1
on p1.person_id = co1.person_id
where floor((extract(year from co1.procedure_date) - p1.year_of_birth)/10) >=9
and co1.procedure_concept_id != co1.procedure_source_concept_id
group by co1.procedure_source_concept_id, stratum_2"

# 600 age 18-29
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3,count_value,source_count_value)
select 0, 3102 as analysis_id,
CAST(co1.procedure_concept_id AS STRING) as stratum_1,
'2' as stratum_2,'Procedure' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co2
on p2.person_id = co2.person_id where co2.procedure_source_concept_id=co1.procedure_concept_id
and (extract(year from co2.procedure_date) - p2.year_of_birth) >= 18 and
(extract(year from co2.procedure_date) - p2.year_of_birth) < 30) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1
on p1.person_id = co1.person_id
where (extract(year from co1.procedure_date) - p1.year_of_birth) >= 18 and
(extract(year from co1.procedure_date) - p1.year_of_birth) < 30
and co1.procedure_concept_id > 0
group by co1.procedure_concept_id, stratum_2
union all
select 0, 3102 as analysis_id,CAST(co1.procedure_source_concept_id AS STRING) as stratum_1,'2' as stratum_2,
'Procedure' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1
on p1.person_id = co1.person_id
where (extract(year from co1.procedure_date) - p1.year_of_birth) >= 18 and
(extract(year from co1.procedure_date) - p1.year_of_birth) < 30
group by co1.procedure_source_concept_id, stratum_2"

# 3106 current age histogram data
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value,source_count_value)
select 0, 3106 as analysis_id,
CAST(co1.procedure_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Procedure' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co2 on p2.person_id = co2.person_id where co2.procedure_source_concept_id=co1.procedure_concept_id
and floor((extract(year from current_date()) - p2.year_of_birth)/10) >=3 and floor((extract(year from current_date()) - p2.year_of_birth)/10) <9) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1
on p1.person_id = co1.person_id
where floor((extract(year from current_date()) - p1.year_of_birth)/10) >=3 and floor((extract(year from current_date()) - p1.year_of_birth)/10) < 9
and co1.procedure_concept_id > 0
group by co1.procedure_concept_id, stratum_2
union all
select 0, 3106 as analysis_id,CAST(co1.procedure_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Procedure' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1
on p1.person_id = co1.person_id
where floor((extract(year from current_date()) - p1.year_of_birth)/10) >=3 and floor((extract(year from current_date()) - p1.year_of_birth)/10) < 9
and co1.procedure_concept_id != co1.procedure_source_concept_id
group by co1.procedure_source_concept_id, stratum_2"

# 3106 current age histogram data 90+
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value,source_count_value)
select 0, 3106 as analysis_id,
CAST(co1.procedure_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Procedure' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co2 on p2.person_id = co2.person_id where co2.procedure_source_concept_id=co1.procedure_concept_id
and floor((extract(year from current_date()) - p2.year_of_birth)/10) >=9) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1
on p1.person_id = co1.person_id
where floor((extract(year from current_date()) - p1.year_of_birth)/10) >=9
and co1.procedure_concept_id > 0
group by co1.procedure_concept_id, stratum_2
union all
select 0, 3106 as analysis_id,CAST(co1.procedure_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Procedure' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1
on p1.person_id = co1.person_id
where floor((extract(year from current_date()) - p1.year_of_birth)/10) >=9
and co1.procedure_concept_id != co1.procedure_source_concept_id
group by co1.procedure_source_concept_id, stratum_2"

# 3106 age 18-29
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3,count_value,source_count_value)
select 0, 3106 as analysis_id,
CAST(co1.procedure_concept_id AS STRING) as stratum_1,
'2' as stratum_2,'Procedure' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co2 on p2.person_id = co2.person_id where co2.procedure_source_concept_id=co1.procedure_concept_id
and (extract(year from current_date()) - p2.year_of_birth) >= 18 and
(extract(year from current_date()) - p2.year_of_birth) < 30) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1
on p1.person_id = co1.person_id
where (extract(year from current_date()) - p1.year_of_birth) >= 18 and
(extract(year from current_date()) - p1.year_of_birth) < 30
and co1.procedure_concept_id > 0
group by co1.procedure_concept_id, stratum_2
union all
select 0, 3106 as analysis_id,CAST(co1.procedure_source_concept_id AS STRING) as stratum_1,'2' as stratum_2,
'Procedure' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co1
on p1.person_id = co1.person_id
where (extract(year from current_date()) - p1.year_of_birth) >= 18 and
(extract(year from current_date()) - p1.year_of_birth) < 30
group by co1.procedure_source_concept_id, stratum_2"

# Drugs
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_3, count_value, source_count_value)
select 0, 3000 as analysis_id,
CAST(de1.drug_CONCEPT_ID AS STRING) as stratum_1,'Drug' as stratum_3,
COUNT(distinct de1.PERSON_ID) as count_value,(select COUNT(distinct de2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` de2 where de2.drug_source_concept_id=de1.drug_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` de1
where de1.drug_concept_id > 0
group by de1.drug_CONCEPT_ID
union all
select 0, 3000 as analysis_id,CAST(de1.drug_source_CONCEPT_ID AS STRING) as stratum_1,'Drug' as stratum_3,
COUNT(distinct de1.PERSON_ID) as count_value,
COUNT(distinct de1.PERSON_ID) as source_count_value from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` de1 where
de1.drug_source_concept_id not in (select distinct drug_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\`)
group by de1.drug_source_CONCEPT_ID"

# Drug gender
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3101 as analysis_id,
CAST(co1.drug_concept_id AS STRING) as stratum_1,
CAST(p1.gender_concept_id AS STRING) as stratum_2,'Drug' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co2
on p2.person_id = co2.person_id where co2.drug_source_concept_id=co1.drug_concept_id and p2.gender_concept_id = p1.gender_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1
on p1.person_id = co1.person_id
where co1.drug_concept_id > 0
group by co1.drug_concept_id,
p1.gender_concept_id
union all
select 0, 3101 as analysis_id,CAST(co1.drug_source_concept_id AS STRING) as stratum_1,
CAST(p1.gender_concept_id AS STRING) as stratum_2,'Drug' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1
on p1.person_id = co1.person_id
where co1.drug_source_concept_id not in (select distinct drug_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\`)
group by co1.drug_source_concept_id,p1.gender_concept_id"

# Drug gender identity
# Calculates gender identity counts for drug concepts based on the people' answer to ppi question 1585838
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3107 as analysis_id,
CAST(co1.drug_concept_id AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Drug' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
(select COUNT(distinct ob2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob2 on ob2.person_id=co2.person_id
where co2.drug_source_concept_id=co1.drug_concept_id and ob2.observation_source_concept_id=1585838 and
ob2.value_source_concept_id = ob1.value_source_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1 on ob1.person_id = co1.person_id
where co1.drug_concept_id > 0
and ob1.observation_source_concept_id=1585838
group by co1.drug_concept_id, ob1.value_source_concept_id
union all
select 0, 3107 as analysis_id,CAST(co1.drug_source_concept_id AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Drug' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
COUNT(distinct ob1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on ob1.person_id = co1.person_id
where co1.drug_source_concept_id not in (select distinct drug_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\`)
and ob1.observation_source_concept_id=1585838
group by co1.drug_source_concept_id,ob1.value_source_concept_id"

# Drug race ethnicity
# Calculates race ethnicity counts for drug concepts based on the people' answer to ppi question 1586140
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3108 as analysis_id,
CAST(co1.drug_concept_id AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Drug' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
(select COUNT(distinct ob2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob2 on ob2.person_id=co2.person_id
where co2.drug_source_concept_id=co1.drug_concept_id and ob2.observation_source_concept_id=1586140 and
ob2.value_source_concept_id = ob1.value_source_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1 on ob1.person_id = co1.person_id
where co1.drug_concept_id > 0
and ob1.observation_source_concept_id=1586140
group by co1.drug_concept_id, ob1.value_source_concept_id
union all
select 0, 3108 as analysis_id,CAST(co1.drug_source_concept_id AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Drug' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
COUNT(distinct ob1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on ob1.person_id = co1.person_id
where co1.drug_source_concept_id not in (select distinct drug_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\`)
and ob1.observation_source_concept_id=1586140
group by co1.drug_source_concept_id,ob1.value_source_concept_id"

# Drug age
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3102 as analysis_id,CAST(co1.drug_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.drug_exposure_start_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Drug' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co2 on p2.person_id = co2.person_id where co2.drug_source_concept_id=co1.drug_concept_id
and floor((extract(year from co2.drug_exposure_start_date) - p2.year_of_birth)/10) >=3 and floor((extract(year from co2.drug_exposure_start_date) - p2.year_of_birth)/10) < 9) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1
on p1.person_id = co1.person_id
where floor((extract(year from co1.drug_exposure_start_date) - p1.year_of_birth)/10) >=3 and floor((extract(year from co1.drug_exposure_start_date) - p1.year_of_birth)/10) < 9
and co1.drug_concept_id > 0
group by co1.drug_concept_id, stratum_2
union all
select 0, 3102 as analysis_id,CAST(co1.drug_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.drug_exposure_start_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Drug' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1
on p1.person_id = co1.person_id
where floor((extract(year from co1.drug_exposure_start_date) - p1.year_of_birth)/10) >=3 and floor((extract(year from co1.drug_exposure_start_date) - p1.year_of_birth)/10) < 9
and co1.drug_concept_id != co1.drug_source_concept_id
group by co1.drug_source_concept_id, stratum_2"

# Drug age 90+
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3102 as analysis_id,CAST(co1.drug_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.drug_exposure_start_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Drug' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co2 on p2.person_id = co2.person_id where co2.drug_source_concept_id=co1.drug_concept_id
and floor((extract(year from co2.drug_exposure_start_date) - p2.year_of_birth)/10) >=9) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1
on p1.person_id = co1.person_id
where floor((extract(year from co1.drug_exposure_start_date) - p1.year_of_birth)/10) >=9
and co1.drug_concept_id > 0
group by co1.drug_concept_id, stratum_2
union all
select 0, 3102 as analysis_id,CAST(co1.drug_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.drug_exposure_start_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Drug' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1
on p1.person_id = co1.person_id
where floor((extract(year from co1.drug_exposure_start_date) - p1.year_of_birth)/10) >=9
and co1.drug_concept_id != co1.drug_source_concept_id
group by co1.drug_source_concept_id, stratum_2"

# Drug age decile
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3102 as analysis_id,
CAST(co1.drug_concept_id AS STRING) as stratum_1,
'2' as stratum_2,'Drug' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co2 on p2.person_id = co2.person_id where co2.drug_source_concept_id=co1.drug_concept_id
and (extract(year from co2.drug_exposure_start_date) - p2.year_of_birth) >= 18 and
(extract(year from co2.drug_exposure_start_date) - p2.year_of_birth) < 30) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1
on p1.person_id = co1.person_id
where (extract(year from co1.drug_exposure_start_date) - p1.year_of_birth) >= 18 and
(extract(year from co1.drug_exposure_start_date) - p1.year_of_birth) < 30
and co1.drug_concept_id > 0
group by co1.drug_concept_id, stratum_2
union all
select 0, 3102 as analysis_id,CAST(co1.drug_source_concept_id AS STRING) as stratum_1,'2' as stratum_2,'Drug' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1
on p1.person_id = co1.person_id
where (extract(year from co1.drug_exposure_start_date) - p1.year_of_birth) >= 18 and
(extract(year from co1.drug_exposure_start_date) - p1.year_of_birth) < 30 and co1.drug_concept_id != drug_source_concept_id
group by co1.drug_source_concept_id, stratum_2"

# 3106 Drug current age
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3106 as analysis_id,CAST(co1.drug_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Drug' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co2 on p2.person_id = co2.person_id where co2.drug_source_concept_id=co1.drug_concept_id
and floor((extract(year from current_date()) - p2.year_of_birth)/10) >=3 and floor((extract(year from current_date()) - p2.year_of_birth)/10) < 9 ) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1
on p1.person_id = co1.person_id
where floor((extract(year from current_date()) - p1.year_of_birth)/10) >=3 and floor((extract(year from current_date()) - p1.year_of_birth)/10) < 9
and co1.drug_concept_id > 0
group by co1.drug_concept_id, stratum_2
union all
select 0, 3106 as analysis_id,CAST(co1.drug_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Drug' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1
on p1.person_id = co1.person_id
where floor((extract(year from current_date()) - p1.year_of_birth)/10) >=3 and floor((extract(year from current_date()) - p1.year_of_birth)/10) < 9
and co1.drug_concept_id != co1.drug_source_concept_id
group by co1.drug_source_concept_id, stratum_2"

# 3106 Drug current age 90+
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3106 as analysis_id,CAST(co1.drug_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Drug' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co2 on p2.person_id = co2.person_id where co2.drug_source_concept_id=co1.drug_concept_id
and floor((extract(year from current_date()) - p2.year_of_birth)/10) >=9 ) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1
on p1.person_id = co1.person_id
where floor((extract(year from current_date()) - p1.year_of_birth)/10) >=9
and co1.drug_concept_id > 0
group by co1.drug_concept_id, stratum_2
union all
select 0, 3106 as analysis_id,CAST(co1.drug_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Drug' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1
on p1.person_id = co1.person_id
where floor((extract(year from current_date()) - p1.year_of_birth)/10) >=9
and co1.drug_concept_id != co1.drug_source_concept_id
group by co1.drug_source_concept_id, stratum_2"

# 3106 Drug current age decile 2
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3106 as analysis_id,
CAST(co1.drug_concept_id AS STRING) as stratum_1,
'2' as stratum_2,'Drug' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct p2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 inner join \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co2 on
p2.person_id = co2.person_id where co2.drug_source_concept_id=co1.drug_concept_id
and (extract(year from current_date()) - p2.year_of_birth) >= 18 and
(extract(year from current_date()) - p2.year_of_birth) < 30) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1
on p1.person_id = co1.person_id
where (extract(year from current_date()) - p1.year_of_birth) >= 18 and
(extract(year from current_date()) - p1.year_of_birth) < 30
and co1.drug_concept_id > 0
group by co1.drug_concept_id, stratum_2
union all
select 0, 3106 as analysis_id,CAST(co1.drug_source_concept_id AS STRING) as stratum_1,'2' as stratum_2,'Drug' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co1
on p1.person_id = co1.person_id
where (extract(year from current_date()) - p1.year_of_birth) >= 18 and
(extract(year from current_date()) - p1.year_of_birth) < 30 and co1.drug_concept_id != drug_source_concept_id
group by co1.drug_source_concept_id, stratum_2"

# 800	(3000) Number of persons with at least one observation occurrence, by observation_concept_id
echo "Querying observation"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_3, count_value, source_count_value)
select 0, 3000 as analysis_id,
CAST(co1.observation_CONCEPT_ID AS STRING) as stratum_1,'Observation' as stratum_3,
COUNT(distinct co1.PERSON_ID) as count_value,
(select COUNT(distinct co2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co2 where co2.observation_source_concept_id=co1.observation_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1
where co1.observation_concept_id > 0
group by co1.observation_CONCEPT_ID
union all
select 0, 3000 as analysis_id,CAST(co1.observation_source_CONCEPT_ID AS STRING) as stratum_1,'Observation' as stratum_3,
COUNT(distinct co1.PERSON_ID) as count_value,
COUNT(distinct co1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1 where co1.observation_source_concept_id > 0 and
co1.observation_source_concept_id not in (select distinct observation_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.observation\`)
group by co1.observation_source_CONCEPT_ID"

# Observation 3101 concept by gender
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3101 as analysis_id,
CAST(co1.observation_concept_id AS STRING) as stratum_1,
CAST(p1.gender_concept_id AS STRING) as stratum_2,'Observation' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct co2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2
on p2.person_id=co2.person_id where co2.observation_source_concept_id=co1.observation_concept_id and p2.gender_concept_id = p1.gender_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1
on p1.person_id = co1.person_id
where co1.observation_concept_id > 0
group by co1.observation_concept_id, p1.gender_concept_id
union all
select 0, 3101 as analysis_id,
CAST(co1.observation_source_concept_id AS STRING) as stratum_1,
CAST(p1.gender_concept_id AS STRING) as stratum_2,'Observation' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1
on p1.person_id = co1.person_id
where co1.observation_source_concept_id > 0
and co1.observation_source_concept_id not in (select distinct observation_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.observation\`)
group by co1.observation_source_concept_id, p1.gender_concept_id"

# Observation 3107 concept by gender identity
# Calculates gender identity counts for observation concepts based on the people' answer to ppi question 1585838
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3107 as analysis_id,
CAST(co1.observation_concept_id AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Observation' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
(select COUNT(distinct co2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob2 on ob2.person_id=co2.person_id
where co2.observation_source_concept_id=co1.observation_concept_id and ob2.observation_source_concept_id=1585838 and
ob2.value_source_concept_id = ob1.value_source_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1 on ob1.person_id = co1.person_id
where co1.observation_concept_id > 0 and ob1.observation_source_concept_id=1585838
group by co1.observation_concept_id, ob1.value_source_concept_id
union all
select 0, 3107 as analysis_id,
CAST(co1.observation_source_concept_id AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Observation' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
COUNT(distinct ob1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on ob1.person_id = co1.person_id
where co1.observation_source_concept_id > 0
and co1.observation_source_concept_id not in (select distinct observation_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.observation\`)
and ob1.observation_source_concept_id=1585838
group by co1.observation_source_concept_id, ob1.value_source_concept_id"

# Observation 3108 concept by race ethnicity
# Calculates race ethnicity counts for observation concepts based on the people' answer to ppi question 1586140
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3108 as analysis_id,
CAST(co1.observation_concept_id AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Observation' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
(select COUNT(distinct co2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob2 on ob2.person_id=co2.person_id
where co2.observation_source_concept_id=co1.observation_concept_id and ob2.observation_source_concept_id=1586140 and
ob2.value_source_concept_id = ob1.value_source_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1 on ob1.person_id = co1.person_id
where co1.observation_concept_id > 0 and ob1.observation_source_concept_id=1586140
group by co1.observation_concept_id, ob1.value_source_concept_id
union all
select 0, 3108 as analysis_id,
CAST(co1.observation_source_concept_id AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Observation' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
COUNT(distinct ob1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on ob1.person_id = co1.person_id
where co1.observation_source_concept_id > 0
and co1.observation_source_concept_id not in (select distinct observation_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.observation\`)
and ob1.observation_source_concept_id=1586140
group by co1.observation_source_concept_id, ob1.value_source_concept_id"

# Observation (3102)	Number of persons with   concept id by  age decile  30+ yr old deciles
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_3, count_value, source_count_value)
select 0, 3102 as analysis_id,
CAST(co1.observation_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.observation_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Observation' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct co2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 on p2.person_id=co2.person_id
where co2.observation_source_concept_id=co1.observation_concept_id
and floor((extract(year from co2.observation_date) - p2.year_of_birth)/10) >=3 and floor((extract(year from co2.observation_date) - p2.year_of_birth)/10) < 9) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1
on p1.person_id = co1.person_id
where co1.observation_concept_id > 0 and floor((extract(year from co1.observation_date) - p1.year_of_birth)/10) >=3 and floor((extract(year from co1.observation_date) - p1.year_of_birth)/10) < 9
group by co1.observation_concept_id, stratum_2
union all
select 0, 3102 as analysis_id,CAST(co1.observation_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.observation_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Observation' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1
on p1.person_id = co1.person_id
where co1.observation_source_concept_id > 0 and floor((extract(year from co1.observation_date) - p1.year_of_birth)/10) >=3 and floor((extract(year from co1.observation_date) - p1.year_of_birth)/10) < 9
and co1.observation_concept_id != co1.observation_source_concept_id
group by co1.observation_source_concept_id, stratum_2
"

# Observation (3102)	Number of persons with   concept id by  age decile  90+ yr old deciles
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_3, count_value, source_count_value)
select 0, 3102 as analysis_id,
CAST(co1.observation_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.observation_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Observation' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct co2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 on p2.person_id=co2.person_id
where co2.observation_source_concept_id=co1.observation_concept_id
and floor((extract(year from co2.observation_date) - p2.year_of_birth)/10) >=9) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1
on p1.person_id = co1.person_id
where co1.observation_concept_id > 0 and floor((extract(year from co1.observation_date) - p1.year_of_birth)/10) >=9
group by co1.observation_concept_id, stratum_2
union all
select 0, 3102 as analysis_id,CAST(co1.observation_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.observation_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Observation' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1
on p1.person_id = co1.person_id
where co1.observation_source_concept_id > 0 and floor((extract(year from co1.observation_date) - p1.year_of_birth)/10) >=9
and co1.observation_concept_id != co1.observation_source_concept_id
group by co1.observation_source_concept_id, stratum_2
"

# Observation (3102)	Number of persons with concept id by  age decile  < 20 yr old decile 1
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3102 as analysis_id,
CAST(co1.observation_concept_id AS STRING) as stratum_1,
'2' as stratum_2,'Observation' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct co2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 on p2.person_id=co2.person_id where co2.observation_source_concept_id=co1.observation_concept_id
and (extract(year from co2.observation_date) - p2.year_of_birth) >= 18 and (extract(year from co2.observation_date) - p2.year_of_birth) < 30) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1
on p1.person_id = co1.person_id
where co1.observation_concept_id > 0 and (extract(year from co1.observation_date) - p1.year_of_birth) >= 18 and (extract(year from co1.observation_date) - p1.year_of_birth) < 30
group by co1.observation_concept_id, stratum_2
union all
select 0, 3102 as analysis_id,CAST(co1.observation_source_concept_id AS STRING) as stratum_1,
'2' as stratum_2,'Observation' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1
on p1.person_id = co1.person_id
where co1.observation_concept_id > 0 and (extract(year from co1.observation_date) - p1.year_of_birth) >= 18 and (extract(year from co1.observation_date) - p1.year_of_birth) < 30 and co1.observation_concept_id != co1.observation_source_concept_id
group by co1.observation_source_concept_id, stratum_2
"

# Observation (3106)	Number of persons with   concept id by  current age decile  30+ yr old deciles
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_3, count_value, source_count_value)
select 0, 3106 as analysis_id,
CAST(co1.observation_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Observation' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct co2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 on p2.person_id=co2.person_id
where co2.observation_source_concept_id=co1.observation_concept_id
and floor((extract(year from current_date()) - p2.year_of_birth)/10) >=3 and floor((extract(year from current_date()) - p2.year_of_birth)/10) < 9 ) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1
on p1.person_id = co1.person_id
where co1.observation_concept_id > 0 and floor((extract(year from current_date()) - p1.year_of_birth)/10) >=3 and floor((extract(year from current_date()) - p1.year_of_birth)/10) < 9
group by co1.observation_concept_id, stratum_2
union all
select 0, 3106 as analysis_id,CAST(co1.observation_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Observation' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1
on p1.person_id = co1.person_id
where co1.observation_source_concept_id > 0 and floor((extract(year from current_date()) - p1.year_of_birth)/10) >=3 and floor((extract(year from current_date()) - p1.year_of_birth)/10) < 9
and co1.observation_concept_id != co1.observation_source_concept_id
group by co1.observation_source_concept_id, stratum_2
"

# Observation (3106)	Number of persons with   concept id by  current age decile  30+ yr old deciles
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_3, count_value, source_count_value)
select 0, 3106 as analysis_id,
CAST(co1.observation_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Observation' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct co2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 on p2.person_id=co2.person_id
where co2.observation_source_concept_id=co1.observation_concept_id
and floor((extract(year from current_date()) - p2.year_of_birth)/10) >=9 ) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1
on p1.person_id = co1.person_id
where co1.observation_concept_id > 0 and floor((extract(year from current_date()) - p1.year_of_birth)/10) >=9
group by co1.observation_concept_id, stratum_2
union all
select 0, 3106 as analysis_id,CAST(co1.observation_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Observation' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1
on p1.person_id = co1.person_id
where co1.observation_source_concept_id > 0 and floor((extract(year from current_date()) - p1.year_of_birth)/10) >=9
and co1.observation_concept_id != co1.observation_source_concept_id
group by co1.observation_source_concept_id, stratum_2
"

# Observation (3106)	Number of persons with concept id by current age decile  18 - 29 yr old decile 2
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3106 as analysis_id,
CAST(co1.observation_concept_id AS STRING) as stratum_1,
'2' as stratum_2,'Observation' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct co2.PERSON_ID) from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 on p2.person_id=co2.person_id where co2.observation_source_concept_id=co1.observation_concept_id
and (extract(year from current_date()) - p2.year_of_birth) >= 18 and (extract(year from current_date()) - p2.year_of_birth) < 30) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1
on p1.person_id = co1.person_id
where co1.observation_concept_id > 0 and (extract(year from current_date()) - p1.year_of_birth) >= 18 and (extract(year from current_date()) - p1.year_of_birth) < 30
group by co1.observation_concept_id, stratum_2
union all
select 0, 3106 as analysis_id,CAST(co1.observation_source_concept_id AS STRING) as stratum_1,
'2' as stratum_2,'Observation' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` co1
on p1.person_id = co1.person_id
where co1.observation_concept_id > 0 and (extract(year from current_date()) - p1.year_of_birth) >= 18 and (extract(year from current_date()) - p1.year_of_birth) < 30 and co1.observation_concept_id != co1.observation_source_concept_id
group by co1.observation_source_concept_id, stratum_2
"

# Measurement concept by gender
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3101 as analysis_id,
CAST(co1.measurement_concept_id AS STRING) as stratum_1,
CAST(p1.gender_concept_id AS STRING) as stratum_2,'Measurement' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct co2.person_id) from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 on p2.person_id=co2.person_id
where co2.measurement_source_concept_id=co1.measurement_concept_id and p2.gender_concept_id=p1.gender_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1
on p1.person_id = co1.person_id
where co1.measurement_concept_id > 0
group by co1.measurement_concept_id, p1.gender_concept_id
union all
select 0, 3101 as analysis_id,
CAST(co1.measurement_source_concept_id AS STRING) as stratum_1,
CAST(p1.gender_concept_id AS STRING) as stratum_2,'Measurement' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1
on p1.person_id = co1.person_id
where co1.measurement_source_concept_id > 0
and co1.measurement_source_concept_id not in (select distinct measurement_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\`)
group by co1.measurement_source_concept_id, p1.gender_concept_id"

# Measurement concept by gender identity
# Calculates gender identity counts for measurement concepts based on the people' answer to ppi question 1585838
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3107 as analysis_id,
CAST(co1.measurement_concept_id AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Measurement' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
(select COUNT(distinct co2.person_id) from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob2 on ob2.person_id=co2.person_id
where co2.measurement_source_concept_id=co1.measurement_concept_id
and ob2.observation_source_concept_id=1585838 and
ob2.value_source_concept_id = ob1.value_source_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1 on ob1.person_id = co1.person_id
where co1.measurement_concept_id > 0 and ob1.observation_source_concept_id=1585838
group by co1.measurement_concept_id, ob1.value_source_concept_id
union all
select 0, 3107 as analysis_id,
CAST(co1.measurement_source_concept_id AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Measurement' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
COUNT(distinct ob1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on ob1.person_id = co1.person_id
where co1.measurement_source_concept_id > 0
and co1.measurement_source_concept_id not in (select distinct measurement_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\`)
and ob1.observation_source_concept_id=1585838
group by co1.measurement_source_concept_id, ob1.value_source_concept_id"

# Measurement concept by race ethnicity
# Calculates race ethnicity counts for measurement concepts based on the people' answer to ppi question 1586140
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3108 as analysis_id,
CAST(co1.measurement_concept_id AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Measurement' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
(select COUNT(distinct co2.person_id) from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob2 on ob2.person_id=co2.person_id
where co2.measurement_source_concept_id=co1.measurement_concept_id
and ob2.observation_source_concept_id=1586140 and
ob2.value_source_concept_id = ob1.value_source_concept_id) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1 on ob1.person_id = co1.person_id
where co1.measurement_concept_id > 0 and ob1.observation_source_concept_id=1586140
group by co1.measurement_concept_id, ob1.value_source_concept_id
union all
select 0, 3108 as analysis_id,
CAST(co1.measurement_source_concept_id AS STRING) as stratum_1,
CAST(ob1.value_source_concept_id AS STRING) as stratum_2,'Measurement' as stratum_3,
COUNT(distinct ob1.PERSON_ID) as count_value,
COUNT(distinct ob1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on ob1.person_id = co1.person_id
where co1.measurement_source_concept_id > 0
and co1.measurement_source_concept_id not in (select distinct measurement_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\`)
and ob1.observation_source_concept_id=1586140
group by co1.measurement_source_concept_id, ob1.value_source_concept_id"

# Measurement by age deciles
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3102 as analysis_id,
CAST(co1.measurement_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.measurement_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Measurement' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct co2.person_id) from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 on p2.person_id=co2.person_id where co2.measurement_source_concept_id=co1.measurement_concept_id
and floor((extract(year from co2.measurement_date) - p2.year_of_birth)/10) >=3 and floor((extract(year from co2.measurement_date) - p2.year_of_birth)/10) < 9) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1
on p1.person_id = co1.person_id
where co1.measurement_concept_id > 0 and floor((extract(year from co1.measurement_date) - p1.year_of_birth)/10) >=3 and floor((extract(year from co1.measurement_date) - p1.year_of_birth)/10) < 9
group by co1.measurement_concept_id, stratum_2
union all
select 0, 3102 as analysis_id,
CAST(co1.measurement_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.measurement_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Measurement' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1
on p1.person_id = co1.person_id
where co1.measurement_source_concept_id > 0 and floor((extract(year from co1.measurement_date) - p1.year_of_birth)/10) >=3 and floor((extract(year from co1.measurement_date) - p1.year_of_birth)/10) < 9
and co1.measurement_concept_id!=co1.measurement_source_concept_id
group by co1.measurement_source_concept_id, stratum_2"

# Measurement by age deciles 90+
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3102 as analysis_id,
CAST(co1.measurement_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.measurement_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Measurement' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct co2.person_id) from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 on p2.person_id=co2.person_id where co2.measurement_source_concept_id=co1.measurement_concept_id
and floor((extract(year from co2.measurement_date) - p2.year_of_birth)/10) >=9) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1
on p1.person_id = co1.person_id
where co1.measurement_concept_id > 0 and floor((extract(year from co1.measurement_date) - p1.year_of_birth)/10) >=9
group by co1.measurement_concept_id, stratum_2
union all
select 0, 3102 as analysis_id,
CAST(co1.measurement_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from co1.measurement_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Measurement' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1
on p1.person_id = co1.person_id
where co1.measurement_source_concept_id > 0 and floor((extract(year from co1.measurement_date) - p1.year_of_birth)/10) >=9
and co1.measurement_concept_id!=co1.measurement_source_concept_id
group by co1.measurement_source_concept_id, stratum_2"

# Measurement  18 - 29 yr old decile 2
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3102 as analysis_id,
CAST(co1.measurement_concept_id AS STRING) as stratum_1,
'2' as stratum_2,'Measurement' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct co2.person_id) from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2
on p2.person_id=co2.person_id where co2.measurement_source_concept_id=co1.measurement_concept_id
and (extract(year from co2.measurement_date) - p2.year_of_birth) >= 18 and (extract(year from co2.measurement_date) - p2.year_of_birth) < 30 ) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1
on p1.person_id = co1.person_id
where co1.measurement_concept_id > 0 and (extract(year from co1.measurement_date) - p1.year_of_birth) >= 18 and (extract(year from co1.measurement_date) - p1.year_of_birth) < 30
group by co1.measurement_concept_id, stratum_2
union all
select 0, 3102 as analysis_id,
CAST(co1.measurement_source_concept_id AS STRING) as stratum_1,
'2' as stratum_2,'Measurement' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1
on p1.person_id = co1.person_id
where co1.measurement_source_concept_id > 0 and (extract(year from co1.measurement_date) - p1.year_of_birth) >= 18 and (extract(year from co1.measurement_date) - p1.year_of_birth) < 30 and co1.measurement_concept_id!=co1.measurement_source_concept_id
group by co1.measurement_source_concept_id, stratum_2
"

# 3106 Measurement by current age deciles
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3106 as analysis_id,
CAST(co1.measurement_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Measurement' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct co2.person_id) from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 on p2.person_id=co2.person_id where co2.measurement_source_concept_id=co1.measurement_concept_id
and floor((extract(year from current_date()) - p2.year_of_birth)/10) >=3 and floor((extract(year from current_date()) - p2.year_of_birth)/10) < 9 ) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1
on p1.person_id = co1.person_id
where co1.measurement_concept_id > 0 and floor((extract(year from current_date()) - p1.year_of_birth)/10) >=3 and floor((extract(year from current_date()) - p1.year_of_birth)/10) < 9
group by co1.measurement_concept_id, stratum_2
union all
select 0, 3106 as analysis_id,
CAST(co1.measurement_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Measurement' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1
on p1.person_id = co1.person_id
where co1.measurement_source_concept_id > 0 and floor((extract(year from current_date()) - p1.year_of_birth)/10) >=3 and floor((extract(year from current_date()) - p1.year_of_birth)/10) < 9
and co1.measurement_concept_id!=co1.measurement_source_concept_id
group by co1.measurement_source_concept_id, stratum_2"

# 3106 Measurement by current age deciles 90+
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3106 as analysis_id,
CAST(co1.measurement_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Measurement' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct co2.person_id) from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 on p2.person_id=co2.person_id where co2.measurement_source_concept_id=co1.measurement_concept_id
and floor((extract(year from current_date()) - p2.year_of_birth)/10) >=9 ) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1
on p1.person_id = co1.person_id
where co1.measurement_concept_id > 0 and floor((extract(year from current_date()) - p1.year_of_birth)/10) >=9
group by co1.measurement_concept_id, stratum_2
union all
select 0, 3106 as analysis_id,
CAST(co1.measurement_source_concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,'Measurement' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1
on p1.person_id = co1.person_id
where co1.measurement_source_concept_id > 0 and floor((extract(year from current_date()) - p1.year_of_birth)/10) >=9
and co1.measurement_concept_id!=co1.measurement_source_concept_id
group by co1.measurement_source_concept_id, stratum_2"

# 3106 Measurement  current age histogram 18 - 29 yr old decile 2
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2, stratum_3, count_value, source_count_value)
select 0, 3106 as analysis_id,
CAST(co1.measurement_concept_id AS STRING) as stratum_1,
'2' as stratum_2,'Measurement' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
(select COUNT(distinct co2.person_id) from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co2 join \`${BQ_PROJECT}.${BQ_DATASET}.person\` p2 on p2.person_id=co2.person_id where co2.measurement_source_concept_id=co1.measurement_concept_id
and (extract(year from current_date()) - p2.year_of_birth) >= 18 and (extract(year from current_date()) - p2.year_of_birth) < 30 ) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1
on p1.person_id = co1.person_id
where co1.measurement_concept_id > 0 and (extract(year from current_date()) - p1.year_of_birth) >= 18 and (extract(year from current_date()) - p1.year_of_birth) < 30
group by co1.measurement_concept_id, stratum_2
union all
select 0, 3106 as analysis_id,
CAST(co1.measurement_source_concept_id AS STRING) as stratum_1,
'2' as stratum_2,'Measurement' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,
COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co1
on p1.person_id = co1.person_id
where co1.measurement_source_concept_id > 0 and (extract(year from current_date()) - p1.year_of_birth) >= 18 and (extract(year from current_date()) - p1.year_of_birth) < 30 and co1.measurement_concept_id!=co1.measurement_source_concept_id
group by co1.measurement_source_concept_id, stratum_2
"

# Set the survey answer count for all the survey questions that belong to each module
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id,analysis_id,stratum_1,stratum_2,stratum_3,stratum_4,stratum_5,count_value,source_count_value)
SELECT 0 as id, 3110 as analysis_id,CAST(sm.concept_id as string) as stratum_1,CAST(o.observation_source_concept_id as string) as stratum_2,
CAST(o.value_source_concept_id as string) as stratum_3,c.concept_name as stratum_4,cast(sq.question_order_number as string) stratum_5,
Count(*) as count_value, 0 as source_count_value
FROM \`${BQ_PROJECT}.${BQ_DATASET}.observation\` o join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On o.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on c.concept_id = o.value_source_concept_id
where (o.observation_source_concept_id > 0 and o.value_source_concept_id > 0)
group by o.observation_source_concept_id,o.value_source_concept_id,c.concept_name,sm.concept_id,sq.question_order_number
order by CAST(sq.question_order_number as int64) asc"

# Set the survey answer count for all the survey questions that belong to each module(value as number)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id,analysis_id,stratum_1,stratum_2,stratum_4,stratum_5,count_value,source_count_value)
SELECT 0 as id, 3110 as analysis_id,CAST(sm.concept_id as string) as stratum_1,CAST(o.observation_source_concept_id as string) as stratum_2,
CAST(o.value_as_number as string) as stratum_4,cast(sq.question_order_number as string) stratum_5,
Count(*) as count_value,0 as source_count_value
FROM \`${BQ_PROJECT}.${BQ_DATASET}.observation\` o join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On o.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
Where (o.observation_source_concept_id > 0 and o.value_as_number >= 0 )
Group by o.observation_source_concept_id,o.value_as_number,sm.concept_id,sq.question_order_number
order by CAST(sq.question_order_number as int64) asc"

# Survey question answers count by gender
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_3,stratum_4,stratum_5,count_value,source_count_value)
select 0,3111 as analysis_id,CAST(sm.concept_id as string) as stratum_1,CAST(o.observation_source_concept_id as string) as stratum_2,
CAST(o.value_source_concept_id as string) as stratum_3,c.concept_name as stratum_4,
CAST(p.gender_concept_id as string) as stratum_5,count(distinct p.person_id) as count_value,0 as source_count_value
FROM \`${BQ_PROJECT}.${BQ_DATASET}.person\` p inner join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` o on p.person_id = o.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On o.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on c.concept_id = o.value_source_concept_id
where (o.observation_source_concept_id > 0 and o.value_source_concept_id > 0)
group by sm.concept_id,o.observation_source_concept_id,o.value_source_concept_id,o.value_as_number,c.concept_name,p.gender_concept_id,sq.question_order_number
order by CAST(sq.question_order_number as int64) asc"


# Survey question answers count by gender(value_as_number not null)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_4,stratum_5,count_value,source_count_value)
select 0,3111 as analysis_id,CAST(sm.concept_id as string) as stratum_1,CAST(o.observation_source_concept_id as string) as stratum_2,
CAST(o.value_as_number as string) as stratum_4,CAST(p.gender_concept_id as string) as stratum_5,count(distinct p.person_id) as count_value,0 as source_count_value
FROM \`${BQ_PROJECT}.${BQ_DATASET}.person\` p inner join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` o on p.person_id = o.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On o.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (o.observation_source_concept_id > 0 and o.value_as_number >= 0 )
group by sm.concept_id,o.observation_source_concept_id,o.value_as_number,p.gender_concept_id,sq.question_order_number
order by CAST(sq.question_order_number as int64) asc"

# Survey question answers count by gender identity
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_3,stratum_4,stratum_5,count_value,source_count_value)
select 0,3113 as analysis_id,CAST(sm.concept_id as string) as stratum_1,CAST(o.observation_source_concept_id as string) as stratum_2,
CAST(o.value_source_concept_id as string) as stratum_3,c.concept_name as stratum_4,
CAST(p.value_source_concept_id as string) as stratum_5,count(distinct p.person_id) as count_value,0 as source_count_value
FROM \`${BQ_PROJECT}.${BQ_DATASET}.observation\` o join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` p on p.person_id = o.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On o.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on c.concept_id = o.value_source_concept_id
where (o.observation_source_concept_id > 0 and o.value_source_concept_id > 0) and p.observation_source_concept_id=1585838
group by sm.concept_id,o.observation_source_concept_id,o.value_source_concept_id,o.value_as_number,c.concept_name,p.value_source_concept_id,sq.question_order_number
order by CAST(sq.question_order_number as int64) asc"

# Survey question answers count by race-ethnicity
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_3,stratum_4,stratum_5,count_value,source_count_value)
select 0,3114 as analysis_id,CAST(sm.concept_id as string) as stratum_1,CAST(o.observation_source_concept_id as string) as stratum_2,
CAST(o.value_source_concept_id as string) as stratum_3,c.concept_name as stratum_4,
CAST(p.value_source_concept_id as string) as stratum_5,count(distinct p.person_id) as count_value,0 as source_count_value
FROM \`${BQ_PROJECT}.${BQ_DATASET}.observation\` o join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` p on p.person_id = o.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On o.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on c.concept_id = o.value_source_concept_id
where (o.observation_source_concept_id > 0 and o.value_source_concept_id > 0) and p.observation_source_concept_id=1586140
group by sm.concept_id,o.observation_source_concept_id,o.value_source_concept_id,o.value_as_number,c.concept_name,p.value_source_concept_id,sq.question_order_number
order by CAST(sq.question_order_number as int64) asc"

# Survey question answers count by gender identity(value_as_number not null)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_4,stratum_5,count_value,source_count_value)
select 0,3113 as analysis_id,CAST(sm.concept_id as string) as stratum_1,CAST(o.observation_source_concept_id as string) as stratum_2,
CAST(o.value_as_number as string) as stratum_4,CAST(p.value_source_concept_id as string) as stratum_5,count(distinct p.person_id) as count_value,0 as source_count_value
FROM \`${BQ_PROJECT}.${BQ_DATASET}.observation\` p inner join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` o on p.person_id = o.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On o.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (o.observation_source_concept_id > 0 and o.value_as_number >= 0) and p.observation_source_concept_id=1585838
group by sm.concept_id,o.observation_source_concept_id,o.value_as_number,p.value_source_concept_id,sq.question_order_number
order by CAST(sq.question_order_number as int64) asc;"

# Survey question answers count by race-ethnicity(value_as_number not null)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_4,stratum_5,count_value,source_count_value)
select 0,3114 as analysis_id,CAST(sm.concept_id as string) as stratum_1,CAST(o.observation_source_concept_id as string) as stratum_2,
CAST(o.value_as_number as string) as stratum_4,CAST(p.value_source_concept_id as string) as stratum_5,count(distinct p.person_id) as count_value,0 as source_count_value
FROM \`${BQ_PROJECT}.${BQ_DATASET}.observation\` p inner join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` o on p.person_id = o.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On o.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (o.observation_source_concept_id > 0 and o.value_as_number >= 0) and p.observation_source_concept_id=1586140
group by sm.concept_id,o.observation_source_concept_id,o.value_as_number,p.value_source_concept_id,sq.question_order_number
order by CAST(sq.question_order_number as int64) asc;"

# Survey Question Answer Count by age decile  30+ yr old deciles
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_3,stratum_4,stratum_5,count_value,source_count_value)
select 0, 3112 as analysis_id,CAST(sm.concept_id as string) as stratum_1,CAST(o.observation_source_concept_id as string) as stratum_2,
CAST(o.value_source_concept_id as string) as stratum_3,c.concept_name as stratum_4,
CAST(floor((extract(year from o.observation_date) - p.year_of_birth)/10) AS STRING) as stratum_5,COUNT(distinct p.PERSON_ID) as count_value,0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p inner join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` o on p.person_id = o.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On o.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on c.concept_id = o.value_source_concept_id
where (o.observation_source_concept_id > 0 and o.value_source_concept_id > 0)
and floor((extract(year from o.observation_date) - p.year_of_birth)/10) >=3 and floor((extract(year from o.observation_date) - p.year_of_birth)/10) < 9
group by sm.concept_id,o.observation_source_concept_id,o.value_source_concept_id,c.concept_name,stratum_5,sq.question_order_number
order by CAST(sq.question_order_number as int64) asc"

# Survey Question Answer Count by age decile  90+ yr old deciles
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_3,stratum_4,stratum_5,count_value,source_count_value)
select 0, 3112 as analysis_id,CAST(sm.concept_id as string) as stratum_1,CAST(o.observation_source_concept_id as string) as stratum_2,
CAST(o.value_source_concept_id as string) as stratum_3,c.concept_name as stratum_4,
CAST(floor((extract(year from o.observation_date) - p.year_of_birth)/10) AS STRING) as stratum_5,COUNT(distinct p.PERSON_ID) as count_value,0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p inner join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` o on p.person_id = o.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On o.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on c.concept_id = o.value_source_concept_id
where (o.observation_source_concept_id > 0 and o.value_source_concept_id > 0)
and floor((extract(year from o.observation_date) - p.year_of_birth)/10) >=9
group by sm.concept_id,o.observation_source_concept_id,o.value_source_concept_id,c.concept_name,stratum_5,sq.question_order_number
order by CAST(sq.question_order_number as int64) asc"

# Survey Question Answer Count by age decile  <20 yr old decile 1
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_3,stratum_4,stratum_5,count_value,source_count_value)
select 0, 3112 as analysis_id,CAST(sm.concept_id as string) as stratum_1,
CAST(o.observation_source_concept_id as string) as stratum_2,CAST(o.value_source_concept_id as string) as stratum_3,
c.concept_name as stratum_4,
'2' as stratum_5,COUNT(distinct p.PERSON_ID) as count_value,0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p inner join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` o on p.person_id = o.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On o.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on c.concept_id = o.value_source_concept_id
where (o.observation_source_concept_id > 0 and o.value_source_concept_id > 0)
and (extract(year from o.observation_date) - p.year_of_birth) >= 18 and (extract(year from o.observation_date) - p.year_of_birth) < 30
group by sm.concept_id,o.observation_source_concept_id,o.value_source_concept_id,c.concept_name,stratum_5,sq.question_order_number
order by CAST(sq.question_order_number as int64) asc"


# Survey Question Answer Count by age decile  30+ yr old deciles(value as number not null)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_4,stratum_5,count_value,source_count_value)
select 0, 3112 as analysis_id,CAST(sm.concept_id as string) as stratum_1,
CAST(o.observation_source_concept_id as string) as stratum_2,CAST(o.value_as_number as string) as stratum_4,
CAST(floor((extract(year from o.observation_date) - p.year_of_birth)/10) AS STRING) as stratum_5,COUNT(distinct p.PERSON_ID) as count_value,0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p inner join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` o on p.person_id = o.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On o.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (o.observation_source_concept_id > 0 and o.value_as_number >= 0)
and floor((extract(year from o.observation_date) - p.year_of_birth)/10) >=3 and floor((extract(year from o.observation_date) - p.year_of_birth)/10) < 9
group by sm.concept_id,o.observation_source_concept_id,o.value_as_number,stratum_5,sq.question_order_number
order by CAST(sq.question_order_number as int64) asc"

# Survey Question Answer Count by age decile  90+ yr old deciles(value as number not null)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_4,stratum_5,count_value,source_count_value)
select 0, 3112 as analysis_id,CAST(sm.concept_id as string) as stratum_1,
CAST(o.observation_source_concept_id as string) as stratum_2,CAST(o.value_as_number as string) as stratum_4,
CAST(floor((extract(year from o.observation_date) - p.year_of_birth)/10) AS STRING) as stratum_5,COUNT(distinct p.PERSON_ID) as count_value,0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p inner join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` o on p.person_id = o.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On o.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (o.observation_source_concept_id > 0 and o.value_as_number >= 0)
and floor((extract(year from o.observation_date) - p.year_of_birth)/10) >=9
group by sm.concept_id,o.observation_source_concept_id,o.value_as_number,stratum_5,sq.question_order_number
order by CAST(sq.question_order_number as int64) asc"


# Survey Question Answer Count by age decile  <20 yr old decile 1(value as number not null)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_2,stratum_4,stratum_5,count_value,source_count_value)
select 0, 3112 as analysis_id,CAST(sm.concept_id as string) as stratum_1,
CAST(o.observation_source_concept_id as string) as stratum_2,CAST(o.value_as_number as string) as stratum_4,
'2' as stratum_5,COUNT(distinct p.PERSON_ID) as count_value,0 as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p inner join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` o on p.person_id = o.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On o.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (o.observation_source_concept_id > 0 and o.value_as_number >= 0 )
and (extract(year from o.observation_date) - p.year_of_birth) >= 18 and (extract(year from o.observation_date) - p.year_of_birth) < 30
group by sm.concept_id,o.observation_source_concept_id,o.value_as_number,stratum_5,sq.question_order_number
order by CAST(sq.question_order_number as int64) asc"

if [[ "$tables" == *"_mapping_"* ]]; then
    ### Mapping tables has the ehr fetched records linked to the dataset named 'ehr'. So, joining on the mapping tables to fetch only ehr concepts.
    # Condition Domain participant counts
    echo "Getting condition domain participant counts"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
    (id, analysis_id, stratum_1, stratum_3, stratum_5, count_value, source_count_value)
    with condition_concepts as
    (select condition_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.condition_concept_id=c.concept_id
    join \`${BQ_PROJECT}.${BQ_DATASET}._mapping_condition_occurrence\` mm on co.condition_occurrence_id =mm.condition_occurrence_id
    where c.vocabulary_id != 'PPI' and mm.src_dataset_id=(select distinct src_dataset_id from \`${BQ_PROJECT}.${BQ_DATASET}._mapping_condition_occurrence\` where src_dataset_id like '%ehr%')),
    condition_source_concepts as
    (select condition_source_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.condition_source_concept_id=c.concept_id
    join \`${BQ_PROJECT}.${BQ_DATASET}._mapping_condition_occurrence\` mm on co.condition_occurrence_id=mm.src_condition_occurrence_id
    where c.vocabulary_id != 'PPI' and mm.src_dataset_id=(select distinct src_dataset_id from \`${BQ_PROJECT}.${BQ_DATASET}._mapping_condition_occurrence\` where src_dataset_id like '%ehr%')
    and co.condition_source_concept_id not in (select distinct condition_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\`)),
    concepts as
    (select * from condition_concepts union all select * from condition_source_concepts)
    select 0 as id,3000 as analysis_id,'19' as stratum_1,'Condition' as stratum_3,
    CAST((select count(distinct person_id) from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\`) as STRING) as stratum_5,
    (select count(distinct person) from concepts) as count_value,
    0 as source_count_value"

    echo "Getting drug domain participant counts"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
    (id, analysis_id, stratum_1, stratum_3, stratum_5, count_value, source_count_value)
    with drug_concepts as
    (select drug_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.drug_concept_id=c.concept_id
    join \`${BQ_PROJECT}.${BQ_DATASET}._mapping_drug_exposure\` mde on mde.drug_exposure_id=co.drug_exposure_id
    where c.vocabulary_id != 'PPI' and mde.src_dataset_id=(select distinct src_dataset_id from \`${BQ_PROJECT}.${BQ_DATASET}._mapping_drug_exposure\` where src_dataset_id like '%ehr%') ),
    drug_source_concepts as
    (select drug_source_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.drug_source_concept_id=c.concept_id
    join \`${BQ_PROJECT}.${BQ_DATASET}._mapping_drug_exposure\` mde on mde.src_drug_exposure_id=co.drug_exposure_id
    where c.vocabulary_id != 'PPI' and mde.src_dataset_id=(select distinct src_dataset_id from \`${BQ_PROJECT}.${BQ_DATASET}._mapping_drug_exposure\` where src_dataset_id like '%ehr%')
    and co.drug_source_concept_id not in (select distinct drug_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\`)),
    concepts as
    (select * from drug_concepts union all select * from drug_source_concepts)
    select 0 as id,3000 as analysis_id,'13' as stratum_1,'Drug' as stratum_3,
    CAST((select count(distinct person_id) from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\`) as STRING) as stratum_5,
    (select count(distinct person) from concepts) as count_value,
    0 as source_count_value"

    echo "Getting measurement domain participant counts"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
    (id, analysis_id, stratum_1, stratum_3, stratum_5, count_value, source_count_value)
    with measurement_concepts as
    (select measurement_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.measurement_concept_id=c.concept_id
    join \`${BQ_PROJECT}.${BQ_DATASET}._mapping_measurement\` mm on co.measurement_id=mm.measurement_id
    where c.vocabulary_id != 'PPI' and mm.src_dataset_id=(select distinct src_dataset_id from \`${BQ_PROJECT}.${BQ_DATASET}._mapping_measurement\` where src_dataset_id like '%ehr%')),
    measurement_source_concepts as
    (select measurement_source_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.measurement_source_concept_id=c.concept_id
    join \`${BQ_PROJECT}.${BQ_DATASET}._mapping_measurement\` mm on co.measurement_id=mm.src_measurement_id
    where c.vocabulary_id != 'PPI' and mm.src_dataset_id=(select distinct src_dataset_id from \`${BQ_PROJECT}.${BQ_DATASET}._mapping_measurement\` where src_dataset_id like '%ehr%')
    and co.measurement_source_concept_id not in (select distinct measurement_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\`)),
    concepts as
    (select * from measurement_concepts union all select * from measurement_source_concepts)
    select 0 as id,3000 as analysis_id,'21' as stratum_1,'Measurement' as stratum_3,
    CAST((select count(distinct person_id) from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\`) as STRING) as stratum_5,
    (select count(distinct person) from concepts) as count_value,
    0 as source_count_value"

    echo "Getting procedure domain participant counts"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
    (id, analysis_id, stratum_1, stratum_3, stratum_5, count_value, source_count_value)
    with procedure_concepts as
    (select procedure_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.procedure_concept_id=c.concept_id
    join \`${BQ_PROJECT}.${BQ_DATASET}._mapping_procedure_occurrence\` mm on co.procedure_occurrence_id =mm.procedure_occurrence_id
    where c.vocabulary_id != 'PPI' and mm.src_dataset_id=(select distinct src_dataset_id from \`${BQ_PROJECT}.${BQ_DATASET}._mapping_procedure_occurrence\` where src_dataset_id like '%ehr%')),
    procedure_source_concepts as
    (select procedure_source_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.procedure_source_concept_id=c.concept_id
    join \`${BQ_PROJECT}.${BQ_DATASET}._mapping_procedure_occurrence\` mm on co.procedure_occurrence_id=mm.src_procedure_occurrence_id
    where c.vocabulary_id != 'PPI' and mm.src_dataset_id=(select distinct src_dataset_id from \`${BQ_PROJECT}.${BQ_DATASET}._mapping_procedure_occurrence\` where src_dataset_id like '%ehr%')
    and co.procedure_source_concept_id not in (select distinct procedure_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\`)),
    concepts as
    (select * from procedure_concepts union all select * from procedure_source_concepts)
    select 0 as id,3000 as analysis_id,'10' as stratum_1,'Procedure' as stratum_3,
    CAST((select count(distinct person_id) from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\`) as STRING) as stratum_5,
    (select count(distinct person) from concepts) as count_value,
    0 as source_count_value"
else
    ### Test data does not have the mapping tables, so this else block lets the script to fetch domain counts for test data
    # Condition Domain participant counts
    echo "Getting condition domain participant counts"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
    (id, analysis_id, stratum_1, stratum_3, count_value, source_count_value)
    with condition_concepts as
    (select condition_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.condition_concept_id=c.concept_id
    where c.vocabulary_id != 'PPI'),
    condition_source_concepts as
    (select condition_source_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.condition_source_concept_id=c.concept_id
    where c.vocabulary_id != 'PPI'
    and co.condition_source_concept_id not in (select distinct condition_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.condition_occurrence\`)),
    concepts as
    (select * from condition_concepts union all select * from condition_source_concepts)
    select 0 as id,3000 as analysis_id,'19' as stratum_1,'Condition' as stratum_3,(select count(distinct person) from concepts) as count_value,
    0 as source_count_value"

    echo "Getting drug domain participant counts"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
    (id, analysis_id, stratum_1, stratum_3, count_value, source_count_value)
    with drug_concepts as
    (select drug_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.drug_concept_id=c.concept_id
    where c.vocabulary_id != 'PPI'),
    drug_source_concepts as
    (select drug_source_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.drug_source_concept_id=c.concept_id
    where c.vocabulary_id != 'PPI'
    and co.drug_source_concept_id not in (select distinct drug_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.drug_exposure\`)),
    concepts as
    (select * from drug_concepts union all select * from drug_source_concepts)
    select 0 as id,3000 as analysis_id,'13' as stratum_1,'Drug' as stratum_3, (select count(distinct person) from concepts) as count_value, 0 as source_count_value"

    echo "Getting measurement domain participant counts"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
    (id, analysis_id, stratum_1, stratum_3, count_value, source_count_value)
    with measurement_concepts as
    (select measurement_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.measurement_concept_id=c.concept_id
    where c.vocabulary_id != 'PPI' and co.measurement_concept_id not in (3036277,903118,903115,3025315,903135,903136,903126,903111,42528957)),
    measurement_source_concepts as
    (select measurement_source_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.measurement_source_concept_id=c.concept_id
    where c.vocabulary_id != 'PPI' and co.measurement_source_concept_id not in (3036277,903133,903118,903115,3025315,903121,903135,903136,903126,903111,42528957,903120)
    and co.measurement_source_concept_id not in (select distinct measurement_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\`)),
    concepts as
    (select * from measurement_concepts union all select * from measurement_source_concepts)
    select 0 as id,3000 as analysis_id,'21' as stratum_1,'Measurement' as stratum_3, (select count(distinct person) from concepts) as count_value,
    0 as source_count_value"

    echo "Getting participant domain participant counts"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
    (id, analysis_id, stratum_1, stratum_3, count_value, source_count_value)
    with procedure_concepts as
    (select procedure_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.procedure_concept_id=c.concept_id
    where c.vocabulary_id != 'PPI' and c.concept_id not in (3036277,903118,903115,3025315,903135,903136,903126,903111,42528957)),
    procedure_source_concepts as
    (select procedure_source_concept_id as concept,co.person_id as person
    from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.procedure_source_concept_id=c.concept_id
    where c.vocabulary_id != 'PPI' and c.concept_id not in (3036277,903133,903118,903115,3025315,903121,903135,903136,903126,903111,42528957,903120)
    and co.procedure_source_concept_id not in (select distinct procedure_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.procedure_occurrence\`)),
    concepts as
    (select * from procedure_concepts union all select * from procedure_source_concepts)
    select 0 as id,3000 as analysis_id,'10' as stratum_1,'Procedure' as stratum_3, (select count(distinct person) from concepts) as count_value,
    0 as source_count_value"
fi

echo "Getting physical measurements participant counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id, analysis_id, stratum_1, stratum_3, count_value, source_count_value)
with pm_concepts as
(select measurement_concept_id as concept,co.person_id as person
from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.measurement_concept_id=c.concept_id
where c.concept_id in (3036277, 3025315, 3027018, 3031203, 40759207, 903107, 903126, 40765148, 903135, 903136, 3022318, 3012888, 3004249, 903115, 903118, 3038553)),
pm_source_concepts as
(select measurement_source_concept_id as concept,co.person_id as person
from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\` co join \`${BQ_PROJECT}.${BQ_DATASET}.concept\` c on co.measurement_source_concept_id=c.concept_id
where c.concept_id in (3036277, 3025315, 3027018, 3031203, 40759207, 903107, 903126, 40765148, 903135, 903136, 3022318, 3012888, 3004249, 903115, 903118, 3038553)
and co.measurement_source_concept_id not in (select distinct measurement_concept_id from \`${BQ_PROJECT}.${BQ_DATASET}.measurement\`)),
concepts as
(select * from pm_concepts union all select * from pm_source_concepts)
select 0 as id,3000 as analysis_id,'0' as stratum_1,'Physical Measurement' as stratum_3, (select count(distinct person) from concepts) as count_value, 0 as source_count_value"

# Count of people who took each survey
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id,analysis_id,stratum_1,stratum_3,count_value,source_count_value)
SELECT 0 as id, 3000 as analysis_id,CAST(sm.concept_id as string) as stratum_1,
'Survey' as stratum_3,
count(distinct o.person_id) as count_value, count(distinct o.person_id) as source_count_value
FROM \`${BQ_PROJECT}.${BQ_DATASET}.observation\` o join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On o.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
Where (o.observation_source_concept_id > 0 and o.value_source_concept_id > 0)
Group by sm.concept_id"

# Gender breakdown of people who took each survey (Row for combinations of each survey and gender)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id,analysis_id,stratum_1,stratum_2,stratum_3,count_value,source_count_value)
select 0, 3101 as analysis_id,
CAST(sm.concept_id AS STRING) as stratum_1,
CAST(p1.gender_concept_id AS STRING) as stratum_2,'Survey' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on p1.person_id = ob1.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On ob1.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (ob1.observation_source_concept_id > 0 and ob1.value_source_concept_id > 0)
group by sm.concept_id, p1.gender_concept_id"

# Gender identity breakdown of people who took each survey (Row for combinations of each survey and gender)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id,analysis_id,stratum_1,stratum_2,stratum_3,count_value,source_count_value)
select 0, 3107 as analysis_id,
CAST(sm.concept_id AS STRING) as stratum_1,
CAST(p1.value_source_concept_id AS STRING) as stratum_2,'Survey' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` p1 on p1.person_id=ob1.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On ob1.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (ob1.observation_source_concept_id > 0 and ob1.value_source_concept_id > 0) and p1.observation_source_concept_id=1585838
group by sm.concept_id, p1.value_source_concept_id"

# Race ethnicity breakdown of people who took each survey (Row for combinations of each survey and gender)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id,analysis_id,stratum_1,stratum_2,stratum_3,count_value,source_count_value)
select 0, 3108 as analysis_id,
CAST(sm.concept_id AS STRING) as stratum_1,
CAST(p1.value_source_concept_id AS STRING) as stratum_2,'Survey' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1 join \`${BQ_PROJECT}.${BQ_DATASET}.observation\` p1 on p1.person_id=ob1.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On ob1.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (ob1.observation_source_concept_id > 0 and ob1.value_source_concept_id > 0) and p1.observation_source_concept_id=1586140
group by sm.concept_id, p1.value_source_concept_id"

# Age breakdown of people who took each survey (Row for combinations of each survey and age decile)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id,analysis_id,stratum_1,stratum_2,stratum_3,count_value,source_count_value)
select 0, 3102 as analysis_id,
CAST(sm.concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from ob1.observation_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,
  'Survey' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on p1.person_id = ob1.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On ob1.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (ob1.observation_source_concept_id > 0 and ob1.value_source_concept_id > 0)
and floor((extract(year from ob1.observation_date) - p1.year_of_birth)/10) >=3 and floor((extract(year from ob1.observation_date) - p1.year_of_birth)/10) < 9
group by sm.concept_id, stratum_2"

# Age breakdown of people who took each survey (Row for combinations of each survey and age decile) 90+
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id,analysis_id,stratum_1,stratum_2,stratum_3,count_value,source_count_value)
select 0, 3102 as analysis_id,
CAST(sm.concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from ob1.observation_date) - p1.year_of_birth)/10) AS STRING) as stratum_2,
  'Survey' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on p1.person_id = ob1.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On ob1.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (ob1.observation_source_concept_id > 0 and ob1.value_source_concept_id > 0)
and floor((extract(year from ob1.observation_date) - p1.year_of_birth)/10) >=9
group by sm.concept_id, stratum_2"

# Age breakdown of people who took each survey (Row for combinations of each survey and age decile 2)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id,analysis_id,stratum_1,stratum_2,stratum_3,count_value,source_count_value)
select 0, 3102 as analysis_id,
CAST(sm.concept_id AS STRING) as stratum_1,
'2' as stratum_2,
  'Survey' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on p1.person_id = ob1.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On ob1.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (ob1.observation_source_concept_id > 0 and ob1.value_source_concept_id > 0)
and (extract(year from ob1.observation_date) - p1.year_of_birth) >= 18 and (extract(year from ob1.observation_date) - p1.year_of_birth) < 30
group by sm.concept_id, stratum_2"

# Current Age breakdown of people who took each survey (Row for combinations of each survey and age decile)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id,analysis_id,stratum_1,stratum_2,stratum_3,count_value,source_count_value)
select 0, 3106 as analysis_id,
CAST(sm.concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,
  'Survey' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on p1.person_id = ob1.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On ob1.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (ob1.observation_source_concept_id > 0 and ob1.value_source_concept_id > 0)
and floor((extract(year from ob1.observation_date) - p1.year_of_birth)/10) >=3 and floor((extract(year from ob1.observation_date) - p1.year_of_birth)/10) < 9
group by sm.concept_id, stratum_2"

# Current Age breakdown of people who took each survey (Row for combinations of each survey and age decile) 90+
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id,analysis_id,stratum_1,stratum_2,stratum_3,count_value,source_count_value)
select 0, 3106 as analysis_id,
CAST(sm.concept_id AS STRING) as stratum_1,
CAST(floor((extract(year from current_date()) - p1.year_of_birth)/10) AS STRING) as stratum_2,
  'Survey' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on p1.person_id = ob1.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On ob1.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (ob1.observation_source_concept_id > 0 and ob1.value_source_concept_id > 0)
and floor((extract(year from ob1.observation_date) - p1.year_of_birth)/10) >=9
group by sm.concept_id, stratum_2"

# Current age breakdown of people who took each survey (Row for combinations of each survey and age decile 2)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id,analysis_id,stratum_1,stratum_2,stratum_3,count_value,source_count_value)
select 0, 3106 as analysis_id,
CAST(sm.concept_id AS STRING) as stratum_1,
'2' as stratum_2,
  'Survey' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on p1.person_id = ob1.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On ob1.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (ob1.observation_source_concept_id > 0 and ob1.value_source_concept_id > 0)
and (extract(year from current_date()) - p1.year_of_birth) >= 18 and (extract(year from current_date()) - p1.year_of_birth) <= 29
group by sm.concept_id, stratum_2"


# Race breakdown of people who took each survey (Row for combinations of each survey and race)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id,analysis_id,stratum_1,stratum_2,stratum_3,count_value,source_count_value)
select 0, 3103 as analysis_id,
CAST(sm.concept_id AS STRING) as stratum_1,
CAST(p1.race_concept_id as string) as stratum_2,
'Survey' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on p1.person_id = ob1.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On ob1.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (ob1.observation_source_concept_id > 0 and ob1.value_source_concept_id > 0)
and p1.race_concept_id > 0
group by sm.concept_id, stratum_2"

# Ethnicity breakdown of people who took each survey (Row for combinations of each survey and ethnicity)
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.achilles_results\`
(id,analysis_id,stratum_1,stratum_2,stratum_3,count_value,source_count_value)
select 0, 3104 as analysis_id,
CAST(sm.concept_id AS STRING) as stratum_1,
CAST(p1.ethnicity_concept_id as string) as stratum_2,
  'Survey' as stratum_3,
COUNT(distinct p1.PERSON_ID) as count_value,COUNT(distinct p1.PERSON_ID) as source_count_value
from \`${BQ_PROJECT}.${BQ_DATASET}.person\` p1 inner join
\`${BQ_PROJECT}.${BQ_DATASET}.observation\` ob1
on p1.person_id = ob1.person_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_question_map\` sq
On ob1.observation_source_concept_id=sq.question_concept_id
join \`${WORKBENCH_PROJECT}.${WORKBENCH_DATASET}.survey_module\` sm on sq.survey_concept_id = sm.concept_id
where (ob1.observation_source_concept_id > 0 and ob1.value_source_concept_id > 0)
group by sm.concept_id, stratum_2"
