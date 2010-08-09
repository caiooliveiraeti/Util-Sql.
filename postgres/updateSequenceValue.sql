CREATE OR REPLACE FUNCTION "updateSequenceValue" ("schemaIn" varchar) RETURNS text AS
$body$
/*
	Para a procedure funcionar corretamente e necessario adotar alguns padroes.

	Nome da Sequence = NomeDaTabela_seq
	Id da tabela = id_NomeDaTabela

	Autor: Caio Oliveira
	Email: caio@javacia.com.br

*/

DECLARE
    seqs_cursor CURSOR FOR 	select seq.sequence_name, tab.table_name, seq.sequence_schema
							from information_schema.sequences as seq
							inner join information_schema.tables as tab on seq.sequence_schema = tab.table_schema and tab.table_name = substr(seq.sequence_name,1,length(seq.sequence_name)-4)
							where seq.sequence_schema=$1;		
	
    aux_cursor refcursor;
    sequence_schema VARCHAR(255);
    sequence_name VARCHAR(255);
    table_name VARCHAR(255);
    maximoId INTEGER;
    comandoSql text;
BEGIN 
	open seqs_cursor;
	
	LOOP	
		FETCH seqs_cursor INTO sequence_name, table_name, sequence_schema;
		IF not FOUND THEN
			EXIT;
		END IF;
	
		/*Pega o ultimo valor da tabela*/
		comandoSql = 'select max(id_'||table_name||') from '||sequence_schema||'.'||table_name;
		OPEN aux_cursor FOR EXECUTE comandoSql;
		FETCH aux_cursor INTO maximoId;
		CLOSE aux_cursor; 
		
        /*Setando o valor da sequence*/
		IF not maximoId is null THEN
			comandoSql = 'select setval('||quote_literal(sequence_schema||'.'||sequence_name)||','|| maximoId||');';
        	EXECUTE comandoSql;
        else
    		comandoSql = 'select setval('||quote_literal(sequence_schema||'.'||sequence_name)||','|| 1||', false);';
        	EXECUTE comandoSql;
		END IF;
    END LOOP;
    CLOSE seqs_cursor; 
    
    return null;
END;
$body$
LANGUAGE 'plpgsql' VOLATILE CALLED ON NULL INPUT SECURITY INVOKER;

/*Exemplo de chamada*/
select "updateSequenceValue"('dados');
select "updateSequenceValue"('Schema');