#ifndef SEMANTIC_H
#define SEMANTIC_H
#include <map>
#include "command.h"
#include <list>
#include <vector>
#include <string>
#include <set>

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
    jump& get_jump(unsigned line);
    const jump& get_jump(unsigned line) const;
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
    const label& get_label(const std::string& name) const;
    label& get_label(const std::string& name);
    bool label_exists(const std::string& name) const; 
    void add_label(const std::string& name, int line); //throws exception if label already exists
    void add_jump(const jump& jmp);
	void remove_label(const std::string& name);
};

class program {
    void index_jumps_labels();
    void connect_jumps();
public:
    label_list labels;
    jump_list jumps;
    command* root;
    program();
    void generate_bash(int debug = 0);
    void print_program_tree() const;
};

#endif
