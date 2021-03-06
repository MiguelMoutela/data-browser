package org.pmiops.workbench.cdr.dao;
import org.pmiops.workbench.cdr.model.QuestionConcept;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;

import java.util.List;

public interface QuestionConceptDao extends CrudRepository<QuestionConcept, Long> {

    @Query(nativeQuery=true, value="SELECT c.concept_id,c.concept_name,c.domain_id,c.vocabulary_id,c.concept_code,c.count_value,c.prevalence from\n" +
            "concept c \n" +
            "join achilles_results ar on ar.stratum_2=c.concept_id\n" +
            "join survey_question_map sqm on sqm.question_concept_id=ar.stratum_2\n" +
            "where ar.stratum_1=?1 and ar.analysis_id=3110\n" +
            "group by c.concept_id,c.concept_name,c.domain_id,c.vocabulary_id,c.concept_code,c.count_value,c.prevalence,sqm.question_order_number \n" +
            "order by sqm.question_order_number asc")
    List<QuestionConcept> findSurveyQuestions(String survey_concept_id);
}
