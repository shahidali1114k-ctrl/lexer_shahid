/*
 * parser.y - Bison grammar for the mini language
 *
 * Builds an abstract syntax tree (AST) and prints it as text.
 *
 * Build:   bison -d parser.y
 *          flex lexer.l
 *          gcc parser.tab.c lex.yy.c -o mini
 * Run:     ./mini input.txt        (or:  ./mini < input.txt)
 */
%code requires {
    struct Node;
}

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int  yylex(void);
void yyerror(const char *msg);

extern int   yylineno;
extern int   lex_errors;
extern FILE *yyin;

int parse_errors = 0;

/* ---- AST: every node has a label and any number of children ---------- */
typedef struct Node {
    char         *label;
    struct Node **kids;
    int           count;
} Node;

/* make a node; takes ownership of 'label' (must be heap allocated) */
static Node *make(char *label)
{
    Node *n = calloc(1, sizeof(Node));
    n->label = label;
    return n;
}

static Node *make_const(const char *label) { return make(strdup(label)); }

static Node *add_kid(Node *parent, Node *kid)
{
    parent->kids = realloc(parent->kids, (parent->count + 1) * sizeof(Node *));
    parent->kids[parent->count++] = kid;
    return parent;
}

static Node *make2(const char *label, Node *a, Node *b)
{
    return add_kid(add_kid(make_const(label), a), b);
}

static Node *root = NULL;

/* print the tree using |-- and `-- branches */
static void print_tree(const Node *n, const char *prefix, int is_last, int is_root)
{
    if (is_root) {
        printf("%s\n", n->label);
    } else {
        printf("%s%s%s\n", prefix, is_last ? "`-- " : "|-- ", n->label);
    }

    char child_prefix[256];
    snprintf(child_prefix, sizeof child_prefix, "%s%s", prefix,
             is_root ? "" : (is_last ? "    " : "|   "));

    for (int i = 0; i < n->count; i++)
        print_tree(n->kids[i], child_prefix, i == n->count - 1, 0);
}
%}

%define parse.error verbose

%union {
    char        *text;
    struct Node *node;
}

%token LET SHOW IF END
%token EQ NE LE GE
%token <text> ID NUMBER STRING

%type <node> program stmt_list stmt expr cond
%type <text> relop

%left '+' '-'
%left '*' '/'

%%

program
    : stmt_list                         { root = $1; }
    ;

/* a list of statements becomes one PROGRAM node with many children */
stmt_list
    : stmt                              { $$ = add_kid(make_const("PROGRAM"), $1); }
    | stmt_list stmt                    { $$ = add_kid($1, $2); }
    ;

stmt
    : LET ID ';'                        { $$ = add_kid(make_const("DECLARE"), make($2)); }
    | LET ID '=' expr ';'               { $$ = add_kid(add_kid(make_const("DECLARE"), make($2)), $4); }
    | ID '=' expr ';'                   { $$ = make2("ASSIGN", make($1), $3); }
    | SHOW '(' expr ')' ';'             { $$ = add_kid(make_const("SHOW"), $3); }
    | IF '(' cond ')' stmt_list END     { free($5->label);
                                          $5->label = strdup("BODY");
                                          $$ = make2("IF", $3, $5); }
    | error ';'                         { yyerrok; $$ = make_const("ERROR"); }
    ;

cond
    : expr relop expr                   { $$ = make2($2, $1, $3); }
    ;

relop
    : '<'                               { $$ = "<";  }
    | '>'                               { $$ = ">";  }
    | LE                                { $$ = "<="; }
    | GE                                { $$ = ">="; }
    | EQ                                { $$ = "=="; }
    | NE                                { $$ = "!="; }
    ;

expr
    : NUMBER                            { $$ = make($1); }
    | ID                                { $$ = make($1); }
    | STRING                            { $$ = make($1); }
    | expr '+' expr                     { $$ = make2("+", $1, $3); }
    | expr '-' expr                     { $$ = make2("-", $1, $3); }
    | expr '*' expr                     { $$ = make2("*", $1, $3); }
    | expr '/' expr                     { $$ = make2("/", $1, $3); }
    | '(' expr ')'                      { $$ = $2; }
    ;

%%

void yyerror(const char *msg)
{
    parse_errors++;
    fprintf(stderr, "Syntax error (line %d): %s\n", yylineno, msg);
}

int main(int argc, char **argv)
{
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            perror(argv[1]);
            return 1;
        }
    }

    printf("LEXER OUTPUT\n");
    printf("------------\n");

    int status = yyparse();

    if (status == 0 && parse_errors == 0 && lex_errors == 0) {
        printf("\nPARSING SUCCESSFUL\n");
        printf("\nPARSE TREE\n");
        printf("----------\n");
        print_tree(root, "", 1, 1);
        return 0;
    }

    printf("\nPARSING FAILED: %d lexical error(s), %d syntax error(s)\n",
           lex_errors, parse_errors);
    return 1;
}
