#ifndef DEFS_H
#define DEFS_H


// relational operators
enum { EQ, NE, LT, LE, GT, GE, NEG };
static char *rel_ops[] = { "==", "!=", "<", "<=", ">", ">=", "!" };

//i/o redirect
enum { W, A, R };

// wildcards 
enum { ONE, MANY };

#endif
