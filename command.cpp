#include "command.h"
#include <stdexcept>
#include "utility.hpp"


argument::argument(const std::string& value, const argument_type& type) : 
    value(value), type(type) {
}

command::command(const std::string& name, int line) :
    name(name), line(line) {
}

void command::add_child(command* child) {
    children.push_back(child);
}

void command::insert_child(int index, command* child) {
    children.insert(children.begin() + index, child);
}

command* command::get_child(int index) {
    return children.at(index);
}

unsigned command::get_num_children() const {
    return children.size();
}

void command::remove_children(int begin, int end) {
    if (begin < 0) {
        throw std::logic_error("start index is below zero " + toString(begin));
    } else if (unsigned(end + 1) > children.size()) {
        throw std::logic_error("end index " + toString(end) + 
                " is larger than amount of elements " + toString(children.size()));
    }
    children.erase(children.begin() + begin, children.begin() + end + 1);
}

void command::add_option(const std::string& value) {
    args.push_back(argument(value, aOPT));
}

void command::add_options(const std::vector<std::string>& input_vector) {
    for (unsigned i = 0; i < input_vector.size(); ++i) {
        args.push_back(argument(input_vector[i], aOPT));
    }
}

void command::add_string(const std::string& value) {
    args.push_back(argument(value, aSTRING));
}

argument command::get_argument(unsigned index) const {
    return args.at(index);
}

unsigned command::get_num_args() const {
    return args.size();
}

void command::remove_argument(unsigned index) {
    if (index >= args.size()) {
        throw std::logic_error("there aren't that many arguments\n");
    }
    args.erase(args.begin() + index);
}

void command::clear_args() {
    args.clear();
}

int command::get_line() const {
    return line;
}

std::string command::get_name() const {
    return name;
}

void command::set_name(const std::string& input) {
    name = input;
}

command::~command() {
    while (!children.empty()) {
        delete children.back();
        children.pop_back();
    }
}
