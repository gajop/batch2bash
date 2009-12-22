#ifndef SEMANTIC_H
#define SEMANTIC_H
#include <map>
#include <list>
#include <vector>
#include <string>
#include <set>

class parameter_list;

enum parameter_type { SHORT_OPT, LONG_OPT, STRING };

struct parameter {
    std::string name;
    parameter_type type;
};

class parameter_list {
    std::vector<parameter> parameters;
public:
    void add_string();
    void add_option(bool is_short = 1); //short_option: -v -r, long option --verbose --recursive
    parameter get_parameter(int indx) const;
    int get_param_num() const;
};

enum command_type { cJUMP, cLABEL, cNORMAL };

class command {
public:
    command_type type;
    std::vector<command> commands; 
    std::string name;
    parameter_list params; 
    int line;
};


struct jump { 
    std::string label;
    int line;
};

class jump_list {
public:
    std::vector<jump> jumps;
    unsigned num_jumps() const;
    jump& get_jump(unsigned line) const;
    void add_jump(std::string label, int line) const;
    void remove_jump(unsigned line) const;
};

struct label {
    std::set<jump> jumps;
    std::string name;
    int line;
    label(const std::string& name, int line) : name(name), line(line) {}
    //command*
};

class label_list {
    std::set<label> labels;
public:
    unsigned num_labels() const;
    label& get_label(std::string& name) const;
    bool label_exists(const std::string& name) const; 
    void add_label(const std::string& name, int line); //throws exception if label already exists
    void add_jump(const jump& jmp);
};

class program {
public:
    label_list labels;
    jump_list jumps;
    std::vector<command*> commands;
    void done();
    void generate_bash();
};

#endif
