%{
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

// #include "loc.h"
// #include "error.h"
#include "ast.h"
#include "node.h"

#define YYLTYPE LocType

#define MAX_LINE_LENG      256
extern int line_no, col_no, opt_list;
extern char buffer[MAX_LINE_LENG];
extern FILE *yyin;        /* declared by lex */
extern char *yytext;      /* declared by lex */
extern int yyleng;
extern struct nodeType* ASTRoot;

struct nodeType* newOpNode(int op);

extern
#ifdef __cplusplus
"C"
#endif
int yylex(void);
static void yyerror(const char *msg);
extern int yylex_destroy(void);

%}

%locations

// Control Flow Tokens.
%token<node> WHILE
%token<node> DO
%token<node> IF
%token<node> THEN
%token<node> ELSE

// Structural Tokens.
%token<node> PROGRAM
%token<node> PBEGIN
%token<node> END

// Arithmetic Operator Tokens.
%token<node> ADDOP
%token<node> SUBOP 
%token<node> MULOP 
%token<node> DIVOP

// Relational Operator Tokens.
%token<node> LTOP
%token<node> LETOP
%token<node> EQOP
%token<node> GETOP
%token<node> GTOP
%token<node> NEQOP
%token<node> NOT
%token<node> AND
%token<node> OR

// Primitive Tokens.
%token<node> INTEGER
%token<node> REAL
%token<node> IDENTIFIER

// Type Tokens.
%token<node> STRING
%token<node> INTEGERNUM
%token<node> REALNUMBER
%token<node> SCIENTIFIC
%token<node> LITERALSTR
%token<node> FUNCTION
%token<node> PROCEDURE
%token<node> ARRAY
%token<node> VAR

// Assignment/Relation Tokens.
%token<node> ASSIGNMENT
%token<node> OF

// Punctuation Tokens.
%token<node> COMMA
%token<node> LPAREN
%token<node> RPAREN
%token<node> LBRACE
%token<node> RBRACE
%token<node> COLON
%token<node> SEMICOLON
%token<node> DOT
%token<node> DOTDOT

%union {
  struct nodeType *node;
}

    /* Type of Nonterminals */

// %type <var> factor term simple_expression expression variable subprogram_declarations
// %type <varList> expression_list identifier_list parameter_list arguments declarations
// %type <descript> type
// %type <numb> standard_type identifier statement_list optional_statements

%type <node> goal prog identifier_list declarations compound_statement statement_list statement type 
%type <node> subprogram_declarations standard_type subprogram_declaration subprogram_head arguments
%type <node> parameter_list optional_var optional_statements expression procedure_statement 
%type <node> variable tail term simple_expression factor relop expression_list negative boolexpression num
// %start prog
%%
    /* define your snytax here */
goal: prog {
  fprintf(stdout, "goal: prog\n");
  ASTRoot = $1; YYACCEPT;
};
prog : PROGRAM IDENTIFIER LPAREN identifier_list RPAREN SEMICOLON
declarations
subprogram_declarations
compound_statement
DOT {
  $$ = newNode(NODE_PROGRAM);
  addChild($$, $2);
  addChild($$, $4);
  addChild($$, $7);
  addChild($$, $8);
  addChild($$, $9);
  deleteNode($1); deleteNode($3); deleteNode($5); deleteNode($6); deleteNode($9);
}
;

identifier_list: IDENTIFIER {
    $$ = newNode(NODE_LIST);
    addChild($$, $1);
}
| identifier_list COMMA IDENTIFIER {
    $$ = $1;
    addChild($$, $3);
    deleteNode($2);
}
;

declarations: declarations VAR identifier_list COLON type SEMICOLON {
    $$ = $1;
    deleteNode($2);
    addChild($$, $3);
    deleteNode($4);
    addChild($$, $5);
    deleteNode($6);
}
| {
    $$ = newNode(NODE_LIST);
}
;

type: standard_type {
    $$ = $1;
}
| ARRAY LBRACE INTEGERNUM DOTDOT INTEGERNUM RBRACE OF type {
    $$ = newNode(NODE_TYPE_ARRAY);
    deleteNode($2);
    addChild($$, $3);
    deleteNode($4);
    addChild($$, $5);
    deleteNode($6);
    deleteNode($7);
    addChild($$, $8);
}
;

standard_type: INTEGER {
    $$ = newNode(NODE_TYPE_INT);
}
| REAL {
    $$ = newNode(NODE_TYPE_REAL);
}
| STRING {
    $$ = newNode(NODE_TYPE_CHAR);
}
;

subprogram_declarations: subprogram_declarations subprogram_declaration SEMICOLON {
    $$ = $1;
    addChild($$, $2);
    deleteNode($3);
}
| {}
;


subprogram_declaration: subprogram_head
declarations
subprogram_declarations
compound_statement {
    $$ = newNode(NODE_SUBPROG);
    addChild($$, $1);
    addChild($$, $2);
    addChild($$, $3);
    addChild($$, $4);
}
;

subprogram_head: FUNCTION IDENTIFIER arguments COLON standard_type SEMICOLON {
    $$ = newNode(NODE_FUNCTION);
    deleteNode($1);
    addChild($$, $2);
    addChild($$, $3);
    deleteNode($4);
    addChild($$, $5);
    deleteNode($6);
}
| PROCEDURE IDENTIFIER arguments SEMICOLON {
    $$ = newNode(NODE_PROCEDURE);
    addChild($$, $2);
    addChild($$, $3);
    deleteNode($4);
}
;

arguments: LPAREN parameter_list RPAREN {
    $$ = $2;
    deleteNode($1);
    deleteNode($3);
}
| {}
;


parameter_list: optional_var identifier_list COLON type {
    $$ = newNode(NODE_VAR_DECL);
    addChild($$, $2);
    deleteNode($3);
    addChild($$, $4);
}
| optional_var identifier_list COLON type SEMICOLON parameter_list {
    $$ = $6;
    addChild($$, $1);
    addChild($$, $2);
    deleteNode($3);
    deleteNode($4);
    deleteNode($5);
}
;

optional_var: VAR {}
| {}
;

compound_statement: PBEGIN optional_statements END {
    $$ = $2;
    deleteNode($1);
    deleteNode($3);
}
;

/* 拿掉lambda才能避免reduce/reduce conflict */
optional_statements: statement_list { $$ = $1; }
;

statement_list: statement {
    $$ = newNode(NODE_LIST);
}
| statement_list SEMICOLON statement {
    $$ = $1;
    deleteNode($2);
    addChild($$, $3);     
}
;

statement: variable ASSIGNMENT expression {
    $$ = newNode(NODE_ASSIGN_STMT);
    addChild($$, $1);
    addChild($$, $3);
    $1->nodeType = NODE_SYM_REF;
    deleteNode($2);
}
| procedure_statement {
    $$ = $1;
}
| compound_statement {
    $$ = $1;
}
| IF expression THEN statement ELSE statement {
    $$ = newNode(NODE_IF);
    deleteNode($1);
    deleteNode($3);
    deleteNode($5);
    addChild($$, $2);
    addChild($$, $4);
    addChild($$, $6);
}
| WHILE expression DO statement {
    $$ = newNode(NODE_WHILE);
    deleteNode($1);
    deleteNode($3);
    addChild($$, $2);  
    addChild($$, $4);
}
| {}
;

variable: IDENTIFIER tail {
    $$ = newNode(NODE_VAR);
    $$->string = $1->string;
    addChild($$, $1); addChild($$, $2);
}
;

tail: LBRACE expression RBRACE tail {
    $$ = $4;
    deleteNode($1);
    deleteNode($3);
    addChild($$, $2);
}
| {}
;

procedure_statement: IDENTIFIER {
    $$ = $1;
    $$->nodeType = NODE_VAR_OR_PROC;
}
| IDENTIFIER LPAREN expression_list RPAREN {
    $$ = newNode(NODE_PROC_STMT);
    addChild($$, $1); addChild($$, $3);
    deleteNode($2); deleteNode($4);
}
;

expression_list: expression {
    $$ = newNode(NODE_LIST);
    addChild($$, $1);
}
| expression_list COMMA expression {
    $$ = $1;
    deleteNode($2);
    addChild($$, $3);
}
;

expression: boolexpression {
    $$ = $1;
}
| boolexpression AND boolexpression {
    $$ = newOpNode(AND);
    deleteNode($2);
    addChild($$, $1);
    addChild($$, $3);
}
| boolexpression OR boolexpression {
    $$ = newOpNode(OR);
    deleteNode($2);
    addChild($$, $1);
    addChild($$, $3); 
}
;

boolexpression: simple_expression  { $$ = $1; }
| simple_expression relop simple_expression {
    $$ = newOpNode($2->op);
    addChild($$, $1); addChild($$, $3);
}
;

// arithmeticOperation
simple_expression: term { $$ = $1; }
| simple_expression ADDOP term {
    $$ = newOpNode(ADDOP);
    addChild($$, $1); addChild($$, $3);
    deleteNode($2);
}
| simple_expression SUBOP term {
    $$ = newOpNode(SUBOP);
    addChild($$, $1); addChild($$, $3);
    deleteNode($2);
}
;

term: factor  { $$ = $1; }
| term MULOP factor  { 
    $$ = newOpNode(MULOP);
    addChild($$, $1);
    addChild($$, $3);
    deleteNode($2);
}
| term DIVOP factor  {
    $$ = newOpNode(DIVOP);
    addChild($$, $1);
    addChild($$, $3);
    deleteNode($2);
}
;

/* 透過SUBOP num 來表示負數 */
num: INTEGERNUM {
   $$ = newNode(NODE_INT); $$->iValue = -($1->iValue);
}
| REALNUMBER {
    $$ = newNode(NODE_REAL); $$->rValue = -($1->rValue);
}
;

negative: SUBOP INTEGERNUM {
   $$ = newNode(NODE_INT); $$->iValue = -($2->iValue);
    deleteNode($1);
}
| SUBOP REALNUMBER {
    $$ = newNode(NODE_REAL); $$->rValue = -($2->rValue);
    deleteNode($1);
}
;

factor: IDENTIFIER tail {
    $$ = newNode(NODE_SYM_REF);
    $$->string = $1->string;
    addChild($$, $1); addChild($$, $2);
}
| IDENTIFIER LPAREN expression_list RPAREN {
    $$ = newNode(NODE_PROC_STMT);
    addChild($$, $1); addChild($$, $3);
    deleteNode($2); deleteNode($4);
}
| num { $$ = $1; }
| negative { $$ = $1; }
| LPAREN expression RPAREN {
    $$ = $2;
    deleteNode($1); deleteNode($3);
}
| NOT factor {
    $$ = newNode(NODE_OP);
    $$->op = OP_NOT;
    addChild($$, $2);
    deleteNode($1);
}
| LITERALSTR {
    $$ = newNode(NODE_CHAR);
    char *str = malloc(sizeof(char)*50);
    strcpy(str, $1->string);
    $$->string = str;
}
;

relop: LTOP { $$->op = OP_LT;  }
| GTOP      { $$->op = OP_GT;  }
| EQOP      { $$->op = OP_EQ;  }
| GETOP     { $$->op = OP_GE; }
| LETOP     { $$->op = OP_LE; }
| NEQOP     { $$->op = OP_NE; }
;


%%

struct nodeType *ASTRoot;

struct nodeType* newOpNode(int op) {
    struct nodeType *node = newNode(NODE_OP);
    node->op = op;

    return node;
}

void yyerror(const char *msg) {
    fprintf(stderr,
            "[ERROR] line %4d:%3d %s, Unmatched token: %s\n",
            line_no, col_no - yyleng, buffer, yytext);
}

int main(int argc, const char *argv[]) {

    if(argc > 2)
        fprintf( stderr, "Usage: ./parser [filename]\n" ), exit(0);

    FILE *fp = argc == 1 ? stdin : fopen(argv[1], "r");

    if(fp == NULL)
        fprintf( stderr, "Open file error\n" ), exit(-1);

    yyin = fp;
    yyparse();
    printTree(ASTRoot, 0);

    return 0;
}
