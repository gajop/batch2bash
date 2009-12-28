#ifndef COMMAND_H
#define COMMAND_H
#include <string>
#include <vector>
#include <cstdio>

enum argument_type { aOPT, aSTRING };

struct argument {
    std::string value;
    argument_type type;
    argument(const std::string& value, const argument_type& type);
};

class command {
public:
    command(const std::string& name, int line);

    void add_child(command* child); 
    void insert_child(int index, command* child);
    command* get_child(int index);
    int get_num_children() const;
    void remove_children(int begin, int end);

    void add_option(const std::string& value);
    void add_options(const std::vector<std::string>& input_vector);
    void add_string(const std::string& value);
    argument get_argument(int index) const;
    int get_num_args() const;
    void remove_argument(int index);

    int get_line() const;

    std::string get_name() const;
    
private:
    std::vector<command*> children; 
    std::vector<argument> args; 
    int line;
    std::string name;
};

#endif
