#ifndef SEMANTIC_H
#define SEMANTIC_H
#include <map>
#include "command.h"
#include <list>
#include <vector>
#include <string>
#include <set>

class program {
    void index_jumps_labels();
    void connect_jumps();
    void convert_goto();
    void generate_code();
    command* root;
public:
    program();
    command* get_root();
    /* generates the bash equivalent of the semantic tree
     * a multi step process of code generation where steps are:
     * 1. index all jumps and labels
     * 2. connect the above mentioned jumps and labels
     * 3. convert all jumps and labels into ifs/whiles and similar
     * 4. generate bash file with a 1:1 match
     * */
    void generate_bash(int debug = 0);
    /* prints semantic tree
     * prints the name of the commands of the semantic tree
     * with the given indentation
     * */
    void print_program_tree() const;
};

#endif
