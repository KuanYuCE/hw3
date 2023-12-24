%{
/*
 * scanner.l
 *
 * lex input file for pascal scanner
 *
 */

#include <stdio.h>
#include <string.h>
#include "parser.h"
#include "node.h"

int fileno(FILE *);

#define YY_USER_ACTION     col_no += yyleng; // note this line

#define MAX_LINE_LENG      256
#define LIST       strcat(buffer, yytext)
#define LIST_FLUSH do{ if(opt_list) printf("%s", buffer); *buffer = 0; }while(0)
#define LOG(TYPE) do{ LIST; if(opt_token) fprintf(stderr, "token(type:%-10s) on line %4d, %3d : %s\n", #TYPE, line_no, col_no - yyleng, yytext); } while(0)
#define CMD_START
#define CMD_END
#define CMD_SCMT

int opt_list = 1, opt_token = 0;
int line_no = 1, col_no = 1;
char buffer[MAX_LINE_LENG];

int cmnt_count = 0;

struct nodeType* newTokenNode(int tokenType);

%}

%x CMNT
%s PRAGMA

%option nounput
%option noinput

A [aA]
B [bB]
C [cC]
D [dD]
E [eE]
F [fF]
G [gG]
H [hH]
I [iI]
J [jJ]
K [kK]
L [lL]
M [mM]
N [nN]
O [oO]
P [pP]
Q [qQ]
R [rR]
S [sS]
T [tT]
U [uU]
V [vV]
W [wW]
X [xX]
Y [yY]
Z [zZ]

%%
                             /* v could do something */
{P}{R}{O}{G}{R}{A}{M}       {yylval.node = newTokenNode(PROGRAM); return(PROGRAM);    }
{V}{A}{R}                   {yylval.node = newTokenNode(VAR); return(VAR);        }
{A}{R}{R}{A}{Y}             {yylval.node = newTokenNode(ARRAY); return(ARRAY);      }
{O}{F}                      {yylval.node = newTokenNode(OF); return(OF);         }
{I}{N}{T}{E}{G}{E}{R}       {yylval.node = newTokenNode(INTEGER); return(INTEGER);    }
{R}{E}{A}{L}                {yylval.node = newTokenNode(REAL); return(REAL);       }
{S}{T}{R}{I}{N}{G}          {yylval.node = newTokenNode(STRING); return(STRING);     }
{F}{U}{N}{C}{T}{I}{O}{N}    {yylval.node = newTokenNode(FUNCTION); return(FUNCTION);   }
{P}{R}{O}{C}{E}{D}{U}{R}{E} {yylval.node = newTokenNode(PROCEDURE); return(PROCEDURE);  }
{B}{E}{G}{I}{N}             {yylval.node = newTokenNode(PBEGIN); return(PBEGIN);     }
{E}{N}{D}                   {yylval.node = newTokenNode(END); return(END);        }
{I}{F}                      {yylval.node = newTokenNode(IF); return(IF);         }
{T}{H}{E}{N}                {yylval.node = newTokenNode(THEN); return(THEN);       }
{E}{L}{S}{E}                {yylval.node = newTokenNode(ELSE); return(ELSE);       }
{W}{H}{I}{L}{E}             {yylval.node = newTokenNode(WHILE); return(WHILE);      }
{D}{O}                      {yylval.node = newTokenNode(DO); return(DO);         }
{N}{O}{T}                   {yylval.node = newTokenNode(NOT); return(NOT);        }
{A}{N}{D}                   {yylval.node = newTokenNode(AND); return(AND);        }
{O}{R}                      {yylval.node = newTokenNode(OR); return(OR);         }

"("                         {yylval.node = newTokenNode(LPAREN); return(LPAREN);     }
")"                         {yylval.node = newTokenNode(RPAREN); return(RPAREN);     }
";"                         {yylval.node = newTokenNode(SEMICOLON); return(SEMICOLON);  }
"."                         {yylval.node = newTokenNode(DOT); return(DOT);        }
","                         {yylval.node = newTokenNode(COMMA); return(COMMA);      }
":"                         {yylval.node = newTokenNode(COLON); return(COLON);      }
"["                         {yylval.node = newTokenNode(LBRACE); return(LBRACE);     }
"]"                         {yylval.node = newTokenNode(RBRACE); return(RBRACE);     }
".."                        {yylval.node = newTokenNode(DOTDOT); return(DOTDOT);     }
":="                        {yylval.node = newTokenNode(ASSIGNMENT); return(ASSIGNMENT); }
"+"                         {yylval.node = newTokenNode(ADDOP); return(ADDOP);      }
"-"                         {yylval.node = newTokenNode(SUBOP); return(SUBOP);      }
"*"                         {yylval.node = newTokenNode(MULOP); return(MULOP);      }
"/"                         {yylval.node = newTokenNode(DIVOP); return(DIVOP);      }
">"                         {yylval.node = newTokenNode(GTOP); return(GTOP);       }
"<"                         {yylval.node = newTokenNode(LTOP); return(LTOP);       }
"="                         {yylval.node = newTokenNode(EQOP); return(EQOP);       }
">="                        {yylval.node = newTokenNode(GETOP); return(GETOP);      }
"<="                        {yylval.node = newTokenNode(LETOP); return(LETOP);      }
"!="                        {yylval.node = newTokenNode(NEQOP); return(NEQOP);      }

  /* define identifier here */
[a-zA-Z]([a-zA-Z0-9])*  { yylval.node = newTokenNode(IDENTIFIER); yylval.node->string = (char*) malloc(yyleng+1); strcpy(yylval.node->string, yytext); return(IDENTIFIER); }

  /* define INTEGERNUM, REALNUMBER, SCIENTIFIC here */

[0-9]+ { yylval.node = newTokenNode(INTEGERNUM); yylval.node->valueValid = VALUE_I_VALID; yylval.node->iValue = atoi(yytext); return(INTEGERNUM);  }
[0-9]+\.[0-9]+ { yylval.node = newTokenNode(REALNUMBER); yylval.node->valueValid = VALUE_R_VALID; yylval.node->rValue=atof(yytext); return(REALNUMBER); }

([0-9]+|[0-9]+\.[0-9]+)[Ee][+-]?[0-9]+ {
    yylval.node = newTokenNode(SCIENTIFIC);
    return(SCIENTIFIC);
}

  /* define single/multiple line comment here */

"//".* { LIST; CMD_SCMT; }

"/*" { LIST; CMD_START; BEGIN CMNT; cmnt_count += 1; }
<CMNT>. { LIST; }
<CMNT>"/*" { LIST; cmnt_count += 1; }
<CMNT>\n { LIST; LIST_FLUSH; line_no++, col_no = 1; }
<CMNT>"*/" {
  if (cmnt_count > 1) {
     LIST; cmnt_count -= 1;
  } else {
     LIST; CMD_END; BEGIN INITIAL; cmnt_count=0;
  }
}

  /* define string constant (LITERALSTR) here */
\"[^"]*\" {
    if ('\\' == yytext[yyleng-2]) {
        yyless(yyleng-1);
        yymore();
    } else {
        yylval.node = newTokenNode(LITERALSTR);
        return (LITERALSTR);
    };
}
  /* define pragma here */
#[ \t]*pragma[ \t]+list[ \t]+on { LIST; opt_list=1; }
#[ \t]*pragma[ \t]+list[ \t]+off { LIST; opt_list=0; }


[ \t\f\r]    LIST;

\n {
  LIST;
  LIST_FLUSH;
  line_no++, col_no = 1;
}

.  { LIST; fprintf(stderr, "[ERROR] line %4d:%3d lexical analyzer error %s\n", line_no, col_no - yyleng, yytext); }

%%

struct nodeType* newTokenNode(int tokenType) {
  struct nodeType *node = newNode(NODE_TOKEN);
  node->tokenType = tokenType;
  return node;
}

