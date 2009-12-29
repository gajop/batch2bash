#include "semantic.h"
#include "codegen.h"
#include <stdexcept>
#include <algorithm>
#include <stack>
#include <set>
#include "utility.hpp"

struct jump { 
    std::string label;
    std::string var_name;
    bool var_set; 
    command* predicate_command; //faster changing
    int line;
    jump(const std::string& label, unsigned line) : label(label), line(line) { 
        var_set = false;
    }
    friend int operator <(const jump& lhs, const jump& rhs);
    friend int operator ==(const jump& lhs, const jump& rhs);
};

class jump_list {
public:
    std::vector<jump> jumps;
    unsigned num_jumps() const;
    jump& get_jump(int line);
    const jump& get_jump(int line) const;
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

label_list labels;
jump_list jumps;

enum block_type { bSIMPLE, bCOND, bLABEL, bHARD, bIGNORE };

struct block {
    std::vector<block> child_blocks;
    std::vector<jump*> child_jumps;
    command* comm;
    block_type type;
    block(command* comm) : comm(comm) {}
    union jump_label {
        label *labl;
        jump *jmp;
    } jmplabel;
    friend block operator +(const block& lhs, const block& rhs);
};

block operator +(const block& lhs, const block& rhs) {
    block ret(lhs);
    ret.child_blocks.insert(ret.child_blocks.end(), rhs.child_blocks.begin(),
            rhs.child_blocks.end());
    ret.type = bSIMPLE; // right?
    return ret;
}

enum s_type { NONE = -1, LABEL, JUMP };
struct previous {
    s_type type;
    std::vector<block>::iterator pos;
    previous(s_type type, std::vector<block>::iterator pos) : type(type), pos(pos) {}
};

block generate_hidden_if(std::vector<block>::iterator begin,
        std::vector<block>::iterator end, const std::string& predicate) {
    command* if_comm = new command("if", begin->comm->get_line());
    if_comm->add_option("not");
    if_comm->add_string(predicate);
    //ADD IF COMMAND PREDICATE HERE
    command* compound_comm = new command("compound", begin->comm->get_line());
    if_comm->add_child(compound_comm);
    for (std::vector<block>::iterator i = begin + 1; i != end; ++i) {
        compound_comm->add_child(i->comm);
    }
    block ret(if_comm);
    ret.type = bSIMPLE;
    return ret;
}

block generate_hidden_while(std::vector<block>::iterator begin,
        std::vector<block>::iterator end, const std::string& predicate) {
    command* while_comm = new command("while", begin->comm->get_line());
    //ADD WHILE COMMAND PREDICATE HERE
    while_comm->add_string(predicate);
    command* compound_comm = new command("compound", begin->comm->get_line());
    while_comm->add_child(compound_comm);
    for (std::vector<block>::iterator i = begin + 1; i != end + 1; ++i) {
        compound_comm->add_child(i->comm);
    }
    block ret(while_comm);
    ret.type = bSIMPLE;
    return ret;
}

block recursive_conv_goto(command* parent, program* shared_program) {
    block ret = block(parent);
    if (!parent->get_num_children()) {
        if (parent->get_name() == "goto") { 
            ret.type = bCOND;
            ret.jmplabel.jmp = &jumps.get_jump(parent->get_line());
            ret.child_jumps.push_back(&jumps.get_jump(parent->get_line()));
            int line = parent->get_line();
            delete parent;
            parent = new command("set", line);
            ret.comm = parent;
            ret.jmplabel.jmp->var_name = shared_program->new_var();
            parent->add_string(ret.jmplabel.jmp->var_name); //check if this is okay
            parent->add_string("=");
            parent->add_string("1");
            ret.jmplabel.jmp->var_set = true;
            ret.jmplabel.jmp->predicate_command = parent;
            //need to create an assignment to a variable here instead of goto
        } else if (parent->get_name() == "label") {
            ret.type = bLABEL;
            try {
                ret.jmplabel.labl = &labels.get_label(parent->get_argument(0).value);
            } catch(std::logic_error& err) {
                //assume label is unused, somewhat ugly to do it this way but oh well
                ret.type = bIGNORE;
            }
        } else {
            ret.type = bSIMPLE;
        }
        return ret;
    }
    std::vector<block> child_blocks;
    std::vector<label*> child_labels;
    std::vector<std::vector<jump*> > child_jumps; //recursively
    for (int i = 0; i < parent->get_num_children(); ++i) {
        block result = recursive_conv_goto(parent->get_child(i), shared_program);
        switch (result.type) {
            case bSIMPLE :
                if (!child_blocks.empty() && child_blocks.back().type == bSIMPLE) {
                    child_blocks.back() = child_blocks.back() + result;
                    // simple_block : simple_block simple_block;
                } else {
                    child_blocks.push_back(result);
                }
                break;
            case bCOND : 
                child_blocks.push_back(result);
                child_jumps.push_back(result.child_jumps);
                break;
            case bHARD :
                // scream recursively ;)
                break;
            case bLABEL : // just one label, in no block
                child_blocks.push_back(result);
                child_labels.push_back(result.jmplabel.labl);
                fprintf(stderr, "label line : %d\n", result.jmplabel.labl->line);
                break;
            case bIGNORE :
                parent->remove_children(i, i--);
                fprintf(stderr, "unused label at\n");
                break;
        }
    }

    // first find all hidden loops and convert them to simple blocks
    if (child_jumps.size() && child_labels.size()) {
    int label_counter = 0, jump_counter = 0;
    int line = -1;
    std::stack<previous> prev;
    for (std::vector<block>::iterator i = child_blocks.begin(); 
            i != child_blocks.end();) {
        line = i->comm->get_line();
        if (label_counter < child_labels.size() &&
                line == child_labels[label_counter]->line) {
            if (child_labels[label_counter]->jumps.size() == 1 && !prev.empty() && 
                    prev.top().type == JUMP && jump_counter >= 1 &&
                    child_jumps[jump_counter - 1].size() == 1 &&
                    child_labels[label_counter]->jumps.back() ==
                    *child_jumps[jump_counter - 1].front()) {
                // COND1 SIMPLE* LABEL1 -> COND1 IF!1 SIMPLE* FI!1
                int begin, end;
                for (int j = 0; j < parent->get_num_children(); ++j) {
                    if (parent->get_child(j) == prev.top().pos->comm) {
                        begin = j;
                    } else if (parent->get_child(j) == i->comm) {
                        end = j;
                    }
                }
                block new_block = generate_hidden_if(prev.top().pos, i, 
                        child_jumps[jump_counter -1].front()->var_name);
                child_blocks.insert(i + 1, new_block);
                child_blocks.erase(prev.top().pos + 1, i++);
                parent->insert_child(begin + 1, new_block.comm);
                parent->remove_children(begin + 2, end + 2);
                child_labels.erase(child_labels.begin() + label_counter); 
                child_jumps.erase(child_jumps.begin() + --jump_counter);
                prev.pop();
                continue;
            } else {
                prev.push(previous(LABEL, i));
                ++label_counter;
            }
		} else if (jump_counter < child_jumps.size() && 
                child_jumps[jump_counter].size() == 1 &&
                line == child_jumps[jump_counter].front()->line) {
            if (!prev.empty() && prev.top().type == LABEL && label_counter >= 1 && 
                    child_labels[label_counter - 1]->jumps.size() == 1 && 
                    child_labels[label_counter - 1]->jumps.back() ==
                    *child_jumps[jump_counter].front()) {
                // LABEL1 SIMPLE* COND1 -> WHILE1 SIMPLE* COND1 DONE
                int begin, end;
                for (int j = 0; j < parent->get_num_children(); ++j) {
                    if (parent->get_child(j) == prev.top().pos->comm) {
                        begin = j;
                    } else if (parent->get_child(j) == i->comm) {
                        end = j;
                    }
                }
                block new_block = generate_hidden_while(prev.top().pos, i,
                       child_jumps[jump_counter].front()->var_name);
                child_blocks.insert(i + 1, new_block);
                child_blocks.erase(prev.top().pos + 1, i++);
                command* comm = parent->get_child(begin);
                int __line = comm->get_line();
                delete comm;
                comm = new command("set", line);
                comm->add_string(child_jumps[jump_counter].front()->var_name); //check this
                comm->add_string("=");
                comm->add_string("1");
                parent->insert_child(begin + 1, new_block.comm);
                parent->remove_children(begin + 2, end + 2);
                child_labels.erase(child_labels.begin() + --label_counter);
                child_jumps.erase(child_jumps.begin() + jump_counter);
                prev.pop();
                continue;
            } else {
                prev.push(previous(JUMP, i));
                ++jump_counter;
            }
        }
        ++i;
    }
    }
    // check if any of the remaining labels have jumps that aren't any of the child jumps
    for (int i = 0; i < child_labels.size(); ++i) {
        // so slow :<
        int counter = 0;
        for (int j = 0; j < child_jumps.size(); ++j) {
            for (int k = 0; k < child_jumps[j].size(); ++k) {
                if (child_jumps[j][k]->label == child_labels[i]->name) {
                    ++counter;
                }
            }
        }
        if (counter < child_labels.size()) { //there are jumps that aren't happening here
            ret.type = bHARD;
            fprintf(stderr, "you are doing it wrong! or i'm parsing it wrong\n");
            return ret; // scream 
        }
    }
    // if here life is good
   
/* 
 *  LEAVING MULTIJUMPS FOR LATER... first test this
    // now if there are any remaining child_labels and corresponding jumps enclose it all in a big while loop and put ifs inside
    for (int i = 0; i < child_blocks.size(); ++i) {

    }
*/
    ret.child_blocks = child_blocks;
	for (std::vector<std::vector<jump*> >::iterator i = child_jumps.begin();
            i != child_jumps.end(); ++i) {
		for (std::vector<jump*>::iterator j = i->begin(); j != i->end(); ++j) {
			ret.child_jumps.push_back(*j);
		}
	}
    if (child_labels.size() > 0) { // there are some child_labels in this block to which no jump has been performed to
        ret.type = bHARD;
    } else if (child_jumps.size() > 0) {
        ret.type = bCOND;
    } else {
        ret.type = bSIMPLE;
    }
    return ret;        
}

struct tree_frame {
    command* com;
    int visited;
    tree_frame(command* com, int visited = 0) : com(com), visited(visited) { }
};

void program::index_jumps_labels() {
    labels.labels.clear();
    jumps.jumps.clear();
    std::stack<tree_frame> parents;
    parents.push(tree_frame(root));
    tree_frame* current;
    while (!parents.empty()) {
        current = &parents.top();
        if (!current->visited) {
            if (current->com->get_name() == "label") {
                labels.add_label(current->com->get_argument(0).value,
                            current->com->get_line());
            } else if (current->com->get_name() == "goto") {
                jumps.jumps.push_back(
                        jump(current->com->get_argument(0).value,
                            current->com->get_line()));
            }
        }
        if (current->visited < current->com->get_num_children()) {
            parents.push(tree_frame(current->com->get_child(current->visited++)));
        } else {
            parents.pop();
        }
    }
}

void program::connect_jumps() { 
	for (std::vector<jump>::iterator i = jumps.jumps.begin();
            i != jumps.jumps.end(); ++i) {
		labels.add_jump(*i);
    } 
    label_list unused = labels;
    // read the info file, all the documentation is there
	for (std::vector<jump>::iterator i = jumps.jumps.begin();
            i != jumps.jumps.end(); ++i) {
		if (unused.label_exists(i->label)) {
			unused.remove_label(i->label);
        } else {
            throw std::logic_error("jump to an unknown label");
        }
    }
	for (std::vector<label>::iterator i = unused.labels.begin();
            i != unused.labels.end(); ++i) {
        labels.remove_label(i->name);
    }
}

void program::convert_goto() {
    block ret = recursive_conv_goto(root, this);
    print_vars();
    if (ret.type == bHARD) { 
        fprintf(stderr, "not possible to convert goto");
    }
}

void program::generate_code() {
    std::stack<tree_frame> traversal_stack; // meh double memory, but hey, just pointers...
    std::vector<command*> parents; 
    parents.push_back(root);
    traversal_stack.push(tree_frame(root));
    tree_frame* current;
    int level = 0;
    std::string generated_code;
    printf("#!/bin/bash\n");
    while (!parents.empty()) {
        current = &traversal_stack.top();
        if (current->com->get_name() != "root") {
            int old_level = level;
            generated_code = translate(current->com, current->visited, parents, level);
            if (generated_code != "") {
                for (int i = 0; i < ((old_level < level)?old_level:level); ++i) {
                    printf("\t");
                }
                printf("%s\n", generated_code.c_str());
            } 
        }
        if (current->visited < current->com->get_num_children()) {
            traversal_stack.push(tree_frame(current->com->get_child(current->visited++)));
            parents.push_back(traversal_stack.top().com);
        } else {
            traversal_stack.pop();
            parents.pop_back();
        }
    }
}

void program::generate_bash(int debug) {
    index_jumps_labels();
    connect_jumps();
    if (debug != 0) {
        for (std::vector<label>::iterator i = labels.labels.begin(); 
                i != labels.labels.end(); ++i) {
            printf("%d:%s:\n", i->line, i->name.c_str());
            for (std::vector<jump>::iterator j = i->jumps.begin(); 
                    j != i->jumps.end(); ++j) {
                printf("\t%d\n", j->line);
            }
        }
    }
    convert_goto();
    print_program_tree();
    if (debug != 0) {
        printf("\ngenerated code:\n");
    }
    generate_code();
}

bool label_list::label_exists(const std::string& name) const {
    for (std::vector<label>::const_iterator i = labels.begin();
            i != labels.end(); ++i) {
        if (i->name == name) {
            return true;
        }
    }
    return false;
}

void label_list::add_label(const std::string& name, int line) {
    for (std::vector<label>::iterator i = labels.begin();
            i != labels.end(); ++i) {
        if (i->name == name) {
            throw std::logic_error("label already exists"); 
        }
    }
    labels.push_back(label(name, line));
}
void label_list::remove_label(const std::string& name) {
    labels.erase(std::find(labels.begin(), labels.end(), label(name, 42)));
}
unsigned label_list::num_labels() const {
    return labels.size();
}

void label_list::add_jump(const jump& jmp) {
    std::vector<label>::iterator lab = find(labels.begin(), labels.end(),
            label(jmp.label, 42));
	if (lab == labels.end()) {
        throw std::logic_error("label doesn't exists"); 
    } 
    if (find(lab->jumps.begin(), lab->jumps.end(), jmp) == lab->jumps.end()) {
        lab->jumps.push_back(jmp);
    }
}

const label& label_list::get_label(const std::string& name) const {
    for (int i = 0; i < labels.size(); ++i) {
        if (labels[i].name == name) {
            return labels[i];
        }
    }
    throw std::logic_error("label doesn't exist: " + name);
    //return *(find(labels.begin(), labels.end(), label(name, 42)));
}

label& label_list::get_label(const std::string& name) {
    for (int i = 0; i < labels.size(); ++i) {
        if (labels[i].name == name) {
            return labels[i];
        }
    }
    throw std::logic_error("label doesn't exist: " + name);
    //return *(find(labels.begin(), labels.end(), label(name, 42)));
}


const jump& jump_list::get_jump(int line) const {
    for (int i = 0; i < jumps.size(); ++i) {
        if (jumps[i].line == line) {
            return jumps[i];
        }
    }
    throw std::logic_error("jump doesn't exist on line: " + toString(line));
}

jump& jump_list::get_jump(int line) {
    for (int i = 0; i < jumps.size(); ++i) {
        if (jumps[i].line == line) {
            return jumps[i];
        }
    }
    throw std::logic_error("jump doesn't exist on line: " + toString(line));
}

int operator <(const jump& lhs, const jump& rhs) {
	return lhs.line < rhs.line;
}

int operator ==(const jump& lhs, const jump& rhs) {
	return lhs.line == rhs.line;
}

int operator <(const label& lhs, const label& rhs) {
	return lhs.name < rhs.name;
}

int operator ==(const label& lhs, const label& rhs) {
	return lhs.name == rhs.name;
}


program::program() : __last_index(0) { 
    root = new command("root", -1);
}

void program::print_program_tree() const {
    std::stack<tree_frame> parents;
    parents.push(tree_frame(root));
    tree_frame* current;
    int level = 0;
    printf("\nsemantic command tree:\n");
    while (!parents.empty()) {
        current = &parents.top();
        if (!current->visited) {
            for (int i = 0; i < level; ++i) {
                printf("\t");
            }
            printf("%s%d\n", current->com->get_name().c_str(), 
                    current->com->get_num_children());
        }
        if (current->visited < current->com->get_num_children()) {
            parents.push(tree_frame(current->com->get_child(current->visited++)));
            ++level;
        } else {
            parents.pop();
            --level;
        }
    }
}

command* program::get_root() {
    return root;
}


bool variables::exists(const std::string& input) const {
    for (int i = 0; i < vars.size(); ++i) {
        if (vars[i] == input) {
            return true;
        }
    }
    return false;
}
void variables::add(const std::string& input) {
    if (!exists(input)) {
        vars.push_back(input);
    } else {
        throw std::logic_error("variable already exists " + input );
    }
}
void variables::rem(const std::string& input) {
    for (int i = 0; i < vars.size(); ++i) {
        if (vars[i] == input) {
            vars.erase(vars.begin() + i);
            return;
        }
    }
    throw std::logic_error("variable doesn't exists " + input);
}
std::string variables::operator [](int index) const {
    if (num_vars() > index) {
        return vars[index];
    } else {
        throw std::logic_error("not that many variables " + toString(index) );
    }
}
int variables::num_vars() const {
    return vars.size();
}

bool program::var_exists(const std::string& input) const {
    return vars.exists(input);
}

void program::var_add(const std::string& input) {
    vars.add(input);
}
void program::var_rem(const std::string& input) {
    vars.rem(input);
}
std::string program::var_at(int index) const {
    return vars[index];
}
int program::num_vars() const {
    return vars.num_vars();
}
std::string program::new_var() {
    long i = __last_index;
    bool generated = false;
    while (!generated) {
        if (!var_exists("P_" + toString(i))) {
            var_add("P_" + toString(i));
            __last_index = i;
            generated = true;
        }
        ++i;
    }
    return var_at(num_vars() - 1);
}
void program::print_vars() const {
    for (int i = 0; i < num_vars(); ++i) {
        printf("%s\n", var_at(i).c_str());
    }
}
