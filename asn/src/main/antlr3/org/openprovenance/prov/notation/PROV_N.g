/*******************************************************************************
 * Copyright (c) 2011-2012 Luc Moreau
 *******************************************************************************/
grammar PROV_N;

options {
  language = Java;
  output=AST;
}

tokens {
    ID; ATTRIBUTE; ATTRIBUTES; IRI; QNAM; STRING; TYPEDLITERAL; INT; 
    CONTAINER; NAMESPACE; DEFAULTNAMESPACE; NAMESPACES; PREFIX; 

    /* Component 1 */
    ENTITY; ACTIVITY; WGB; USED; WSB; WEB; WIB; WSBA;
    TIME; START; END;

    /* Component 2 */
    AGENT; PLAN; WAT; WAW; AOBO; 
    /* Component 3 */
    WDF; WRO; ORIGINALSOURCE; WQF; TRACEDTO; 
    /* Component 4 */
    SPECIALIZATION; ALTERNATE; 
    /* Component 5 */
    /* Component 6 */
    NOTE; HAN;
}

@header {
package org.openprovenance.prov.notation;
}

@lexer::header {
package org.openprovenance.prov.notation;
}


container
	:	ML_COMMENT* 'container' 
        (namespaceDeclarations)?
		(record | ML_COMMENT)*
		'endContainer'

      -> ^(CONTAINER namespaceDeclarations? record*)
	;


namespaceDeclarations :
        (defaultNamespaceDeclaration | namespaceDeclaration) namespaceDeclaration*
        -> ^(NAMESPACES defaultNamespaceDeclaration? namespaceDeclaration*)
    ;

namespaceDeclaration :
        prefix namespace
        -> ^(NAMESPACE prefix namespace)
    ;

/* Problem: NCNAME is a fragment, and failed to be matched.
Put QNAME instead, but that's not correct, it should really be a NCNAME! */

prefix :
       'prefix' QNAME -> ^(PREFIX QNAME)
    ;


namespace :
        IRI_REF
    ;

defaultNamespaceDeclaration :
        'default' IRI_REF
        ->  ^(DEFAULTNAMESPACE IRI_REF)
    ;

record
	:	(   /* component 1 */

           entityExpression | activityExpression | generationExpression  | usageExpression
         | startExpression | endExpression | communicationExpression | startByActivityExpression

            /* component 2 */
        
        | agentExpression |  associationExpression | attributionExpression | responsibilityExpression

            /* component 3 */

        | derivationExpression | tracedToExpression | hadOriginalSourceExpression | quotationExpression | revisionExpression

            /* component 4 */

        | alternateExpression | specializationExpression

            /* component 5 */
            /* component 6 */ 
        | noteExpression | hasAnnotationExpression
        )
	;

/*
        Component 1: Entities/Activities

*/

entityExpression
	:	'entity' '(' identifier optionalAttributeValuePairs ')'
        -> ^(ENTITY identifier optionalAttributeValuePairs)
	;


activityExpression
	:	'activity' '(' identifier (',' (s=time | '-' ) ',' (e=time | '-'))? optionalAttributeValuePairs ')'
        -> ^(ACTIVITY identifier ^(START $s?) ^(END $e?) optionalAttributeValuePairs )
	;

generationExpression
	:	'wasGeneratedBy' '(' ((id0=identifier | '-') ',')? id2=identifier ',' ((id1=identifier) | '-') ',' ( time | '-' ) optionalAttributeValuePairs ')'
      -> {$id1.tree==null}? ^(WGB ^(ID $id0?) $id2 ^(ID)  ^(TIME time?) optionalAttributeValuePairs)
      -> ^(WGB ^(ID $id0?) $id2 $id1  ^(TIME time?) optionalAttributeValuePairs)
	;

usageExpression
	:	'used' '(' ((id0=identifier | '-') ',')?  id2=identifier ',' id1=identifier ',' ( time | '-' ) optionalAttributeValuePairs ')'
      -> ^(USED ^(ID $id0?)  $id2 $id1 ^(TIME time?) optionalAttributeValuePairs)
	;

startExpression
	:	'wasStartedBy' '(' ((id0=identifier | '-') ',')? id2=identifier ',' ((id1=identifier) | '-') ',' ( time | '-' ) optionalAttributeValuePairs ')'
      -> {$id1.tree==null}? ^(WSB ^(ID $id0?) $id2 ^(ID)  ^(TIME time?) optionalAttributeValuePairs)
      -> ^(WSB ^(ID $id0?) $id2 $id1  ^(TIME time?) optionalAttributeValuePairs)
	;

endExpression
	:	'wasEndedBy' '(' ((id0=identifier | '-') ',')? id2=identifier ',' ((id1=identifier) | '-') ',' ( time | '-' ) optionalAttributeValuePairs ')'
      -> {$id1.tree==null}? ^(WEB ^(ID $id0?) $id2 ^(ID)  ^(TIME time?) optionalAttributeValuePairs)
      -> ^(WEB ^(ID $id0?) $id2 $id1  ^(TIME time?) optionalAttributeValuePairs)
	;


communicationExpression
	:	'wasInformedBy' '(' ((id0=identifier | '-') ',')? id2=identifier ',' id1=identifier optionalAttributeValuePairs ')'
      -> ^(WIB ^(ID $id0?) $id2 $id1 optionalAttributeValuePairs)
	;

startByActivityExpression
	:	'wasStartedByActivity' '(' ((id0=identifier | '-') ',')? id2=identifier ',' id1=identifier optionalAttributeValuePairs ')'
      -> ^(WSBA ^(ID $id0?) $id2 $id1 optionalAttributeValuePairs)
	;


/*
        Component 2: Agents and Responsibility

*/

agentExpression
	:	'agent' '(' identifier optionalAttributeValuePairs	')' 
        -> ^(AGENT identifier optionalAttributeValuePairs )
	;

attributionExpression
	:	'wasAttributedTo' '('  ((id0=identifier | '-') ',')? e=identifier ',' ag=identifier optionalAttributeValuePairs ')'
      -> ^(WAT  ^(ID $id0?) $e $ag optionalAttributeValuePairs)
	;

associationExpression
	:	'wasAssociatedWith' '('  ((id0=identifier | '-') ',')? a=identifier ',' (ag=identifier | '-') ',' (pl=identifier | '-') optionalAttributeValuePairs ')'
      -> {$ag.tree==null}? ^(WAW ^(ID $id0?) $a ^(ID) ^(PLAN $pl?) optionalAttributeValuePairs)
      -> ^(WAW ^(ID $id0?) $a $ag? ^(PLAN $pl?) optionalAttributeValuePairs)
	;

responsibilityExpression
	:	'actedOnBehalfOf' '('   ((id0=identifier | '-') ',')? ag2=identifier ',' ag1=identifier ','  (a=identifier | '-') optionalAttributeValuePairs ')'
      -> {$a.tree==null}? ^(AOBO  ^(ID $id0?) $ag2 $ag1 ^(ID) optionalAttributeValuePairs)
      -> ^(AOBO  ^(ID $id0?) $ag2 $ag1 $a? optionalAttributeValuePairs)
	;



/*
        Component 3: Derivations

*/


derivationExpression
	:	'wasDerivedFrom' '(' ((id0=identifier | '-') ',')? id2=identifier ',' id1=identifier (',' (a=identifier | '-') ',' (g2=identifier  | '-') ',' (u1=identifier | '-') )?	optionalAttributeValuePairs ')'
      -> {$a.tree==null && $g2.tree==null && $u1.tree==null}?
          ^(WDF ^(ID $id0?) $id2 $id1 ^(ID) ^(ID) ^(ID) optionalAttributeValuePairs)
      -> {$a.tree!=null && $g2.tree==null && $u1.tree==null}?
          ^(WDF ^(ID $id0?) $id2 $id1 $a ^(ID) ^(ID) optionalAttributeValuePairs)
      -> {$a.tree==null && $g2.tree!=null && $u1.tree==null}?
          ^(WDF ^(ID $id0?) $id2 $id1 ^(ID) $g2 ^(ID) optionalAttributeValuePairs)
      -> {$a.tree!=null && $g2.tree!=null && $u1.tree==null}?
          ^(WDF ^(ID $id0?) $id2 $id1 $a $g2 ^(ID) optionalAttributeValuePairs)

      -> {$a.tree==null && $g2.tree==null && $u1.tree!=null}?
          ^(WDF ^(ID $id0?) $id2 $id1 ^(ID) ^(ID) $u1 optionalAttributeValuePairs)
      -> {$a.tree!=null && $g2.tree==null && $u1.tree!=null}?
          ^(WDF ^(ID $id0?) $id2 $id1 $a ^(ID) $u1 optionalAttributeValuePairs)
      -> {$a.tree==null && $g2.tree!=null && $u1.tree!=null}?
          ^(WDF ^(ID $id0?) $id2 $id1 ^(ID) $g2 $u1 optionalAttributeValuePairs)
      -> ^(WDF ^(ID $id0?) $id2 $id1 $a $g2 $u1 optionalAttributeValuePairs)
	;


revisionExpression
	:	'wasRevisionOf' '('  ((id0=identifier | '-') ',')? id2=identifier ',' id1=identifier ',' (ag=identifier | '-')optionalAttributeValuePairs ')'
      -> {$ag.tree==null}? ^(WRO ^(ID $id0?) $id2 $id1 ^(ID) optionalAttributeValuePairs)
      -> ^(WRO ^(ID $id0?) $id2 $id1 $ag optionalAttributeValuePairs)
	;


quotationExpression
	:	'wasQuotedFrom' '('  ((id0=identifier | '-') ',')? id2=identifier ',' id1=identifier (',' (ag2=identifier | '-')',' (ag1=identifier | '-'))? optionalAttributeValuePairs ')'
      -> {$ag1.tree==null && $ag2.tree==null}? ^(WQF ^(ID $id0?) $id2 $id1 ^(ID) ^(ID) optionalAttributeValuePairs)
      -> {$ag1.tree!=null && $ag2.tree==null}? ^(WQF ^(ID $id0?) $id2 $id1 $ag1 ^(ID) optionalAttributeValuePairs)
      -> {$ag1.tree==null && $ag2.tree!=null}? ^(WQF ^(ID $id0?) $id2 $id1 ^(ID) $ag2 optionalAttributeValuePairs)
      -> ^(WQF ^(ID $id0?) $id2 $id1 $ag2? $ag1? optionalAttributeValuePairs)
	;

hadOriginalSourceExpression
	:	'hadOriginalSource' '('   ((id0=identifier | '-') ',')? id2=identifier ',' id1=identifier optionalAttributeValuePairs ')'
      -> ^(ORIGINALSOURCE  ^(ID $id0?) $id2 $id1 optionalAttributeValuePairs)
	;

tracedToExpression
	:	'tracedTo' '('  ((id0=identifier | '-') ',')? id2=identifier ',' id1=identifier optionalAttributeValuePairs ')'
      -> ^(TRACEDTO ^(ID $id0?) $id2 $id1 optionalAttributeValuePairs)
	;


/*
        Component 4: Alternate entities

*/

alternateExpression
	:	'alternateOf' '('  identifier ',' identifier ')'
      -> ^(ALTERNATE identifier+)
	;

specializationExpression
	:	'specializationOf' '('  identifier ',' identifier ')'
      -> ^(SPECIALIZATION identifier+)
	;

/*
        Component 5: Collections

*/

/* TODO */

/*
        Component 6: Annotations

*/

noteExpression
	:	'note' '(' identifier optionalAttributeValuePairs	')' 
        -> ^(NOTE identifier optionalAttributeValuePairs )
	;

hasAnnotationExpression
	:	'hasAnnotation' '(' identifier ',' identifier	')' 
        -> ^(HAN identifier+ )
	;





optionalAttributeValuePairs
    :
    (',' '[' attributeValuePairs ']')?
        -> ^(ATTRIBUTES attributeValuePairs?)
    ;


identifier
	:
        QNAME -> ^(ID QNAME)
	;

attribute
	:
        QNAME
	;

attributeValuePairs
	:
        (  | attributeValuePair ( ','! attributeValuePair )* )
	;


attributeValuePair
	:
        attribute '=' literal  -> ^(ATTRIBUTE attribute literal)
	;


time
	:
        xsdDateTime
	;

/* TODO: complete grammar of Literal */
literal
	:
        (STRINGLITERAL -> ^(STRING STRINGLITERAL) |
         INTLITERAL -> ^(INT INTLITERAL) |
         STRINGLITERAL '%%' datatype -> ^(TYPEDLITERAL STRINGLITERAL datatype))
	;

datatype
	:
        (IRI_REF -> ^(IRI IRI_REF)
        |
         QNAME -> ^(QNAM QNAME))
	;
	
/** QNAME Syntax to be agreed, here allows all digits in the local part. */

QNAME	
	:	NCNAME (':' (NCNAME | POSINTLITERAL))?  
	;


fragment CHAR
	: ('\u0009' | '\u000A' | '\u000D' | '\u0020'..'\uD7FF' | '\uE000'..'\uFFFD' )
	;

/* fragment DIGITS 	   
	: ('0'..'9')+
	;
*/

fragment NCNAMESTARTCHAR
	: ('A'..'Z') | '_' | ('a'..'z') | ('\u00C0'..'\u00D6') | ('\u00D8'..'\u00F6') | ('\u00F8'..'\u02FF') | ('\u0370'..'\u037D') | ('\u037F'..'\u1FFF') | ('\u200C'..'\u200D') | ('\u2070'..'\u218F') | ('\u2C00'..'\u2FEF') | ('\u3001'..'\uD7FF') | ('\uF900'..'\uFDCF') | ('\uFDF0'..'\uFFFD')
	;
	
fragment NCNAMECHAR
	:   	NCNAMESTARTCHAR | '-' | '.' | '0'..'9' | '\u00B7' | '\u0300'..'\u036F' | '\u203F'..'\u2040'
	;
	
fragment NAMECHAR	   
	:   ':' 
	| NCNAMECHAR
	;
	
fragment NAMESTARTCHAR
	:  ':' 
	| NCNAMESTARTCHAR
	;
	


	
fragment NCNAME	           
 	:  NCNAMESTARTCHAR NCNAMECHAR* 
	;	


NCNAME_COLON_STAR
	: NCNAME ':' '*'
	;
STAR_COLON_NCNAME
	: '*' ':' NCNAME;

fragment QUOTE	           
	: '"'
	;
	
fragment APOS		   
	: '\''
	;
	
fragment ESCAPEQUOTE 	   
	: QUOTE QUOTE
	;
	
	
fragment ESCAPEAPOS 	   
	: APOS APOS
	;
	
fragment CHARNOQUOTE	   
	: ~(~CHAR | QUOTE)
	;
	
	
fragment CHARNOAPOS	   
	: ~(~CHAR | APOS)
	;


STRINGLITERAL		   
	: (QUOTE (ESCAPEQUOTE | CHARNOQUOTE)* QUOTE) 
	| (APOS  (ESCAPEAPOS | CHARNOAPOS)* APOS)
	;
			 

/* Multiline comment */
ML_COMMENT
    :   '/*' (options {greedy=false;} : .)* '*/' {$channel=HIDDEN;}
    ;


/* 
This lexer rule for comments handles multiline, nested comments
*/
COMMENT_CONTENTS
        :       '(:'
                {
                        $channel=98;
                }
                (       ~('('|':')
                        |       ('(' ~':') => '('
                        |       (':' ~')') => ':'
                        |       COMMENT_CONTENTS
                )*
                ':)'
        ;


WS		
	: (' '|'\r'|'\t'|'\u000C'|'\n')+ {$channel = HIDDEN;}
	;


IRI_REF
  :
  LESS
  ( options {greedy=false;}:
    ~(
      LESS
      | GREATER
      | '"'
      | OPEN_CURLY_BRACE
      | CLOSE_CURLY_BRACE
      | '|'
      | '^'
      | '\\'
      | '`'
      | ('\u0000'..'\u0020')
     )
  )*
  GREATER
  ;


LESS
  :
  '<'
  ;

GREATER
  :
  '>'
  ;
OPEN_CURLY_BRACE
  :
  '{'
  ;

CLOSE_CURLY_BRACE
  :
  '}'
  ;




xsdDateTime: IsoDateTime;



IsoDateTime: (DIGIT DIGIT DIGIT DIGIT '-' DIGIT DIGIT '-' DIGIT DIGIT 'T' DIGIT DIGIT ':' DIGIT DIGIT ':' DIGIT DIGIT ('.' DIGIT (DIGIT DIGIT?)?)? ('Z' | TimeZoneOffset)?)
    ;

fragment DIGIT: '0'..'9';

POSINTLITERAL:
    ('0'..'9')+
    ;

INTLITERAL:
    '-'? POSINTLITERAL
    ;


TimeZoneOffset: ('+' | '-') DIGIT DIGIT ':' DIGIT DIGIT;




