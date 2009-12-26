#include "semantic.h"
#include <stdexcept>
#include <algorithm>
#include <stack>
#include <set>

enum block_type { bSIMPLE, bCOND, bLABEL, bHARD };

struct block {
    std::vector<block> child_blocks;
    std::vector<jump> child_jumps;
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
        std::vector<block>::iterator end) {
    command* if_comm = new command("if", begin->comm->line);
    //ADD IF COMMAND PREDICATE HERE
    command* compound_comm = new command("compound", begin->comm->line);
    if_comm->add_child(compound_comm);
    for (std::vector<block>::iterator i = begin; i != end; ++i) {
        compound_comm->add_child(i->comm);
    }
    block ret(if_comm);
    ret.type = bSIMPLE;
}

block generate_hidden_while(std::vector<block>::iterator begin,
        std::vector<block>::iterator end) {
    command* while_comm = new command("while", begin->comm->line);
    //ADD WHILE COMMAND PREDICATE HERE
    command* compound_comm = new command("compound", begin->comm->line);
    while_comm->add_child(compound_comm);
    for (std::vector<block>::iterator i = begin; i != end; ++i) {
        compound_comm->add_child(i->comm);
    }
    block ret(while_comm);
    ret.type = bSIMPLE;
}

block translate(command* parent, program* shared_program) {
    block ret = block(parent);
    if (parent->children.empty()) {
        fprintf(stderr, "phase one\n");
        if (parent->type == cJUMP) { 
            ret.type = bCOND;
            ret.jmplabel.jmp = &shared_program->jumps.get_jump(parent->line);
        } else if (parent->type == cLABEL) {
            ret.type = bLABEL;
            ret.jmplabel.labl = &shared_program->labels.get_label(parent->name);
        } else {
            ret.type = bSIMPLE;
        }
        return ret;
    }
    fprintf(stderr, "phase two\n");
    std::vector<block> child_blocks;
    std::vector<label> labels;
    std::vector<std::vector<jump> > child_jumps; //recursively
    for (std::vector<command*>::iterator i = parent->children.begin(); 
            i != parent->children.end(); ++i) {
        block result = translate(*i, shared_program);
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
                labels.push_back(*(result.jmplabel.labl));
                break;
        }
    }

    fprintf(stderr, "phase three\n");
    // first find all hidden loops and convert them to simple blocks
    if (child_jumps.size() && labels.size()) {
    int label_counter = 0, jump_counter = 0;
    int line = -1;
    std::stack<previous> prev;
    for (std::vector<block>::iterator i = child_blocks.begin(); 
            i != child_blocks.end(); ++i) {
        line = i->comm->line;
        fprintf(stderr, "phase three-a\n");
        if (label_counter < labels.size() && line == labels[label_counter].line) {
            fprintf(stderr, "phase three-a passed\n");
            if (labels[label_counter].jumps.size() == 1 && !prev.empty() && 
                    prev.top().type == JUMP && jump_counter >= 1 &&
                    child_jumps[jump_counter - 1].size() == 1 &&
                    labels[label_counter].jumps.back() ==
                    child_jumps[jump_counter - 1].front()) {
                // COND1 SIMPLE* LABEL1 -> COND1 IF!1 SIMPLE* FI!1
                fprintf(stderr, "phase three-a1\n");
                block new_block = generate_hidden_if(prev.top().pos, i);
                child_blocks.insert(i + 1, new_block);
                child_blocks.erase(prev.top().pos + 1, i++);
                std::vector<command*>::iterator begin, end;
                for (std::vector<command*>::iterator j = parent->children.begin(); 
                        j != parent->children.end(); ++j) {
                    if (*j == prev.top().pos->comm) {
                        begin = j;
                    } else if (*j == i->comm) {
                        end = j;
                    }
                }
                parent->children.insert(end + 1, new_block.comm);
                parent->children.erase(begin, end);
                labels.erase(labels.begin() + label_counter--); 
                child_jumps.erase(child_jumps.begin() + --jump_counter);
                prev.pop();
            } else {
                prev.push(previous(LABEL, i));
                ++label_counter;
            }
		} else if (jump_counter < child_jumps.size() && 
                line == child_jumps[jump_counter].front().line) {
            fprintf(stderr, "phase three-ab passed\n");
            if (child_jumps[jump_counter].size() == 1 && !prev.empty() &&              
                    prev.top().type == LABEL && label_counter >= 1 && 
                    labels[label_counter - 1].jumps.size() == 1 && 
                    labels[label_counter - 1].jumps.back() ==
                    child_jumps[jump_counter].front()) {
                // LABEL1 SIMPLE* COND1 -> WHILE1 SIMPLE* COND1 DONE
                fprintf(stderr, "phase three-ab2\n");
                block new_block = generate_hidden_while(prev.top().pos, i);
                child_blocks.insert(i + 1, new_block);
                child_blocks.erase(prev.top().pos + 1, i++);
                std::vector<command*>::iterator begin, end;
                for (std::vector<command*>::iterator j = parent->children.begin(); 
                        j != parent->children.end(); ++j) {
                    if (*j == prev.top().pos->comm) {
                        begin = j;
                    } else if (*j == i->comm) {
                        end = j;
                    }
                }
                parent->children.insert(end + 1, new_block.comm);
                parent->children.erase(begin, end);
                labels.erase(labels.begin() + --label_counter);
                child_jumps.erase(child_jumps.begin() + jump_counter--);
                prev.pop();
            } else {
                prev.push(previous(JUMP, i));
                ++jump_counter;
            }
        }
    }
    }
    fprintf(stderr, "phase four\n");
/* 
 *  LEAVING MULTIJUMPS FOR LATER... first test this
    // now if there are any remaining labels and corresponding jumps enclose it all in a big while loop and put ifs inside
    for (int i = 0; i < child_blocks.size(); ++i) {

    }
*/
    ret.child_blocks = child_blocks;
	for (std::vector<std::vector<jump> >::iterator i = child_jumps.begin();
            i != child_jumps.end(); ++i) {
		for (std::vector<jump>::iterator j = i->begin(); j != i->end(); ++j) {
			ret.child_jumps.push_back(*j);
		}
	}
    if (labels.size() > 0) { // there are some labels in this block to which no jump has been performed to
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
            if (current->com->name == "label") {
                labels.labels.push_back(
                        label(current->com->args.get_argument(0).name,
                            current->com->line));
            } else if (current->com->name == "goto") {
                jumps.jumps.push_back(
                        jump(current->com->args.get_argument(0).name,
                            current->com->line));
            }
        }
        if (current->visited < current->com->children.size()) {
            parents.push(tree_frame(current->com->children[current->visited++]));
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
    block ret = translate(root, this);
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

const label& label_list::get_label(std::string& name) const {
    return *(find(labels.begin(), labels.end(), label(name, 42)));
}

label& label_list::get_label(std::string& name) {
    return *(find(labels.begin(), labels.end(), label(name, 42)));
}


const jump& jump_list::get_jump(unsigned line) const {
    return *(find(jumps.begin(), jumps.end(), jump(std::string("42"), line)));
}

jump& jump_list::get_jump(unsigned line) {
    return *(find(jumps.begin(), jumps.end(), jump(std::string("42"), line)));
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

void command::add_child(command* child) {
    children.push_back(child);
}

program::program() { 
    root = NULL;
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
            printf("%s%d\n", current->com->name.c_str(), 
                    current->com->children.size());
        }
        if (current->visited < current->com->children.size()) {
            parents.push(tree_frame(current->com->children[current->visited++]));
            ++level;
        } else {
            parents.pop();
            --level;
        }
    }
}

void argument_list::add_option(const std::string& value) {
    arguments.push_back(argument(value, aOPT));
}

void argument_list::add_string(const std::string& value) {
    arguments.push_back(argument(value, aSTRING));
}

argument argument_list::get_argument(int indx) const {
    return arguments.at(indx);
}

void command::add_option(const std::string& value) {
    args.add_option(value);
}

void command::add_string(const std::string& value) {
    args.add_string(value);
}
