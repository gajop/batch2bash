#ifndef SEMANTIC_H
#define SEMANTIC_H
#include <map>
#include "command.h"
#include <list>
#include <vector>
#include <stdio.h>
#include <string>
#include <set>

class variables {
    std::vector<std::string> vars;
public:
    bool exists(const std::string&) const;
    void add(const std::string&);
    void rem(const std::string&);
    std::string operator [](int index) const;
    int num_vars() const;
};

class program {
    void index_jumps_labels();
    void connect_jumps();
    bool convert_goto();
    void generate_code();
    command* root;
    variables vars;
    int __last_index;
    void print_vars() const; //debug
public:
    program();
    ~program();
    command* get_root();
    bool var_exists(const std::string&) const;
    void var_add(const std::string&);
    void var_rem(const std::string&);
    std::string var_at(int index) const;
    int num_vars() const;
    std::string new_var();
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
