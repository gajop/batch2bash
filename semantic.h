#ifndef SEMANTIC_H
#define SEMANTIC_H
#include <map>
#include <list>
#include <vector>
#include <string>

class program {
public:
    label_list labels;
    std::vector<jump> jumps;
    std::vector<command*> commands;
    void generate_bash();
};

class command {
protected:
    int type;
public:
    std::vector<command> commands; 
    string command_name;
    parameter_list params; 
    std::vector<string> args; //lol
};

struct parameter {
    std::string name;
    enum type = { SHORT_OPT, LONG_OPT, STRING };
};

class parameter_list {
    std::vector<parameter> parameters;
public:
    void add_string();
    void add_option(bool is_short = 1); //short_option: -v -r, long option --verbose --recursive
    parameter get_parameter(int indx) const;
    int get_param_num() const;
};

struct jump { 
    string label;
    int line;
};

struct label {
    std::vector<jump> jumps;
    std::string name;
    int line;
    //command*
};

class label_list {
    std::set<label> labels;
public:
    unsigned num_labels() const;
    string get_label(unsigned num) const;
    bool label_exists(const std::string& label) const; 
    void add_label(const std::string& label); //throws exception if label already exists
    void add_jump(const std::string& label);
};
#endif
