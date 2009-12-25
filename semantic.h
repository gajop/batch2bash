#ifndef SEMANTIC_H
#define SEMANTIC_H
#include <map>
#include <list>
#include <vector>
#include <string>
#include <set>

class parameter_list;

enum parameter_type { SHORT_OPT, LONG_OPT, STRING__ };

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
    std::vector<command*> children; 
    std::string name;
    parameter_list params; 
    int line;
    command(const std::string& name, int line) : name(name), line(line) {}
    void add_child(command* child); 
};


struct jump { 
    std::string label;
    int line;
    jump(const std::string& label, unsigned line) : label(label), line(line) {}
    friend int operator <(const jump& lhs, const jump& rhs);
    friend int operator ==(const jump& lhs, const jump& rhs);
};


class jump_list {
public:
    std::vector<jump> jumps;
    unsigned num_jumps() const;
    const jump& get_jump(unsigned line) const;
    jump& get_jump(unsigned line);
    void add_jump(std::string label, int line) const;
    void remove_jump(unsigned line) const;
};

class label {
public:
    std::vector<jump> jumps;
    std::string name;
    int line;
    label(const std::string& name, int line) : name(name), line(line) {}
	friend int operator <(const label& lhs, const label& rhs);
	friend int operator ==(const label& lhs, const label& rhs);
    //command*
};

class label_list {
public:
	std::vector<label> labels;
    unsigned num_labels() const;
    const label& get_label(std::string& name) const;
    label& get_label(std::string& name);
    bool label_exists(const std::string& name) const; 
    void add_label(const std::string& name, int line); //throws exception if label already exists
    void add_jump(const jump& jmp);
	void remove_label(const std::string& name);
};

class program {
public:
    label_list labels;
    jump_list jumps;
    command* root;
    program();
    void done();
    void generate_bash();
    void print_program_tree() const;
};

#endif
