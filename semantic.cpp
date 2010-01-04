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
    jump& get_jump(const std::string& label);
    const jump& get_jump(const std::string& label) const;
};

class label {
public:
    std::vector<jump> jumps;
    std::string name;
    int line;
    command* comm;
    label(const std::string& name, int line) : name(name), line(line) {}
	friend int operator <(const label& lhs, const label& rhs);
	friend int operator ==(const label& lhs, const label& rhs);
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
    std::vector<command*> comms;
    block_type type;
    block(command* comm) { comms.push_back(comm); }
    union jump_label {
        label *labl;
        jump *jmp;
    } jmplabel;
    friend block operator +(const block& lhs, const block& rhs);
};

block operator +(const block& lhs, const block& rhs) {
    block ret(lhs);
    ret.comms.insert(ret.comms.end(), rhs.comms.begin(), rhs.comms.end());
    ret.type = bSIMPLE; // right?
    return ret;
}

enum s_type { NONE = -1, LABEL, JUMP };
struct previous {
    s_type type;
    int pos;
    previous(s_type type, int pos) : type(type), pos(pos) {}
};

block generate_hidden_if(const std::vector<block>::iterator& begin,
        const std::vector<block>::iterator& end, const std::string& predicate) {
    command* if_comm = new command("if", begin->comms.back()->get_line());
    if_comm->add_option("not");
    if_comm->add_string(predicate);
    //ADD IF COMMAND PREDICATE HERE
    command* compound_comm = new command("compound",
            begin->comms.back()->get_line());
    if_comm->add_child(compound_comm);
    if (begin != end) { //just do it once if begin == end
        for (std::vector<block>::iterator i = begin; i != (end + 1); ++i) {
            for (unsigned j = 0; j < i->comms.size(); ++j) {
                compound_comm->add_child(i->comms[j]);
            }
        }
    } else {
        for (unsigned j = 0; j < begin->comms.size(); ++j) {
            compound_comm->add_child(begin->comms[j]);
        }
    }
    block ret(if_comm);
    ret.type = bSIMPLE;
    return ret;
}

block generate_hidden_while(const std::vector<block>::iterator& begin,
        const std::vector<block>::iterator& end, const std::string& predicate) {
    command* while_comm = new command("while", begin->comms.back()->get_line());
    //ADD WHILE COMMAND PREDICATE HERE
    while_comm->add_string(predicate);
    while_comm->add_string("==");
    while_comm->add_string("1");
    command* compound_comm = new command("compound", begin->comms.back()->get_line());
    while_comm->add_child(compound_comm);
    if (begin != end) { //faster this way 
        for (std::vector<block>::iterator i = begin; i != (end + 1); ++i) {
            for (unsigned j = 0; j < i->comms.size(); ++j) {
                compound_comm->add_child(i->comms[j]);
            }
        }
    } else {
        for (unsigned j = 0; j < begin->comms.size(); ++j) {
            compound_comm->add_child(begin->comms[j]);
        }
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
            parent->set_name("set");
            parent->clear_args();
            ret.jmplabel.jmp->var_name = shared_program->new_var();
            parent->add_string(ret.jmplabel.jmp->var_name); //check if this is okay
            parent->add_string("=");
            parent->add_string("1");
            ret.jmplabel.jmp->var_set = true;
            ret.jmplabel.jmp->predicate_command = parent;
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
    for (unsigned i = 0; i < parent->get_num_children(); ++i) {
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
                break;
            case bIGNORE :
                parent->remove_children(i, i - 1);
                break;
        }
    }
    // first find all hidden loops and convert them to simple blocks
    if (child_jumps.size() && child_labels.size()) {
    unsigned label_counter = 0, jump_counter = 0;
    std::stack<previous> prev;
    for (unsigned i = 0; i < child_blocks.size(); ++i) {
        block current = child_blocks[i];
        int line = current.comms.back()->get_line(); 
        //it's ok even though there can be multiple comms
        if (label_counter < child_labels.size() &&
                current.comms.back() == child_labels[label_counter]->comm) {
            if (child_labels[label_counter]->jumps.size() == 1 && !prev.empty() && 
                    prev.top().type == JUMP && jump_counter >= 1 &&
                    child_jumps[jump_counter - 1].size() == 1 &&
                    child_labels[label_counter]->jumps.back() ==
                    *child_jumps[jump_counter - 1].front()) {
                // COND1 SIMPLE* LABEL1 -> COND1 IF!1 SIMPLE* FI!1
                // prev.top().pos + 1 because we don't want to include cond 
                // i - 1 because we don't need label anymore
                unsigned begin = 0, end = 0;
                // looking for goto/label, there can be only one =)
                for (unsigned j = 0; j < parent->get_num_children(); ++j) {
                    if (parent->get_child(j) == 
                            child_blocks[prev.top().pos].comms.back()) {
                        begin = j;
                    }
                    if (parent->get_child(j) ==
                            child_blocks[i].comms.back()) {
                        end = j;
                    }
                }  
                block new_block = generate_hidden_if(child_blocks.begin() + 
                        prev.top().pos + 1, child_blocks.begin() + (i - 1),
                        child_jumps[jump_counter -1].front()->var_name); 
                // same reasoning for i + 1 here
                child_blocks.erase(child_blocks.begin() + prev.top().pos + 1, 
                        child_blocks.begin() + i + 1);
                child_blocks[prev.top().pos] = new_block;
                // same as above for i + 1
                parent->remove_children(begin + 1, end);
                parent->insert_child(begin + 1, new_block.comms.back());
                i = prev.top().pos;
                child_labels.erase(child_labels.begin() + label_counter); 
                child_jumps.erase(child_jumps.begin() + --jump_counter);
                prev.pop();
            } else {
                prev.push(previous(LABEL, i));
                ++label_counter;
            }
		} else if (jump_counter < child_jumps.size() &&
                line == child_jumps[jump_counter].front()->line) {
            if (child_jumps[jump_counter].size() == 1 && !prev.empty() 
                    && prev.top().type == LABEL && label_counter >= 1 && 
                    child_labels[label_counter - 1]->jumps.size() == 1 && 
                    child_labels[label_counter - 1]->jumps.back() ==
                    *child_jumps[jump_counter].front()) {
                // LABEL1 SIMPLE* COND1 -> SET COND1_P = 1 WHILE1 SIMPLE* COND1 DONE
                unsigned begin = 0, end = 0;
                command* comm = NULL;
                for (unsigned j = 0; j < parent->get_num_children(); ++j) {
                    if (parent->get_child(j) == 
                            child_blocks[prev.top().pos].comms.back()) {
                        begin = j;
                    }
                    if (parent->get_child(j) == child_blocks[i].comms.back()) {
                        end = j;
                    }
                    if (parent->get_child(j) == 
                            child_blocks[prev.top().pos].comms.back()) {
                        comm = parent->get_child(j);
                    }
                }  
                comm->set_name("set");
                comm->clear_args();
                comm->add_string(child_jumps[jump_counter].front()->var_name); //check this
                comm->add_string("=");
                comm->add_string("1");
                // i + 1 because we don't want to add label
                block new_block = generate_hidden_while(child_blocks.begin() + 
                        prev.top().pos + 1, child_blocks.begin() + i,
                       child_jumps[jump_counter].front()->var_name);
                child_blocks.erase(child_blocks.begin() + prev.top().pos + 1,
                        child_blocks.begin() + i);
                child_blocks.insert(child_blocks.begin() + prev.top().pos + 1,
                        new_block);
                parent->remove_children(begin + 1, end); 
                parent->insert_child(begin + 1, new_block.comms.back());
                i = prev.top().pos + 1;
                child_labels.erase(child_labels.begin() + --label_counter);
                child_jumps.erase(child_jumps.begin() + jump_counter);
                prev.pop();
            } else {
                prev.push(previous(JUMP, i));
                ++jump_counter;
            }
        }
    }
    }
    // check if any of the remaining labels have jumps that aren't any of the child jumps
    unsigned counter = 0;
    for (unsigned i = 0; i < child_labels.size(); ++i) {
        // so slow :<
        for (unsigned j = 0; j < child_jumps.size(); ++j) {
            for (unsigned k = 0; k < child_jumps[j].size(); ++k) {
                if (child_jumps[j][k]->label == child_labels[i]->name) {
                    ++counter;
                }
            }
        }
    }
    if (counter < child_labels.size()) { //there are jumps that aren't happening here
        ret.type = bHARD;
        fprintf(stderr, "you are doing it wrong! or i'm parsing it wrong\n"
                "jumps: %d, labels: %u\n", counter, (unsigned)child_labels.size());
        return ret; // scream 
    }
    // if here life is good
   
    // MULTIJUMPS
    // now if there are any remaining child_labels and corresponding jumps enclose it all in a big while loop and put ifs inside
    // TODO ACTUALLY DO IT :P
    if (!child_labels.empty()) {
        std::vector<block>::iterator while_begin;
        std::vector<int> jumps_out;
        for (std::vector<block>::iterator i = child_blocks.begin(); 
                i != child_blocks.end(); ++i) {
            if (i->type == bLABEL || i->type == bCOND) {
                while_begin = i;
                break;
            }
        }
        std::string shared_var = shared_program->new_var();
        command* comm;
        std::map<std::string, int> label_predicate;
        unsigned counter = 1; // when every label is reached predicate is set to 0
        for (unsigned i = 0; i < child_labels.size(); ++i) {
            comm = child_labels[i]->comm;
            comm->remove_argument(comm->get_num_args() - 1);
            comm->set_name("set");
            comm->add_string(shared_var); //check this
            comm->add_string("=");
            comm->add_string("1");
            label_predicate[child_labels[i]->name] = ++counter;
            comm->add_string(toString(counter));  //ugly but works, remove it later
        }
        for (unsigned i = 0; i < child_jumps.size(); ++i) {
            for (unsigned j = 0; j < child_jumps[i].size(); ++j) {
                if (label_predicate.find(child_jumps[i][j]->label) 
                        == label_predicate.end()) {
                    int var_num = label_predicate.size() + 2;
                    jumps_out.push_back(var_num);
                    label_predicate[child_jumps[i][j]->label] = var_num; //hmm 
                }
                child_jumps[i][j]->var_name = shared_var;
                comm = child_jumps[i][j]->predicate_command;
                comm->clear_args();
                comm->add_string(toString(shared_var));
                comm->add_string("=");
                comm->add_string(toString(label_predicate[child_jumps[i][j]->label]));
            }
        //add this command
        }
        unsigned block_begin = 0;
        bool in_block = true;
        int label = 0; // should never happen
        comm = new command("set", parent->get_child(0)->get_line()); //LINE MAYBE good :P
        comm->add_string(shared_var); //check this
        comm->add_string("=");
        comm->add_string("1");
//        child_blocks.insert(, comm);
        for (unsigned i = 0; i < child_blocks.size(); ++i) {
            block current = child_blocks[i];
            if (current.type != bCOND && current.type != bLABEL) {
                in_block = true;
            } else if  (current.type == bCOND) {
                in_block = false;
            } else if (current.type == bLABEL) {
                label = atoi(current.comms.back()->get_argument(
                            current.comms.back()->get_num_args() 
                            - 1).value.c_str());
                child_blocks[i].comms.back()->remove_argument(child_blocks[i].comms.back()->get_num_args() - 1);
                in_block = true;
            }
            if (i + 1 != child_blocks.size() && 
                    child_blocks[i + 1].type == bLABEL && (label || in_block)) {
                in_block = false;
            }
            if (!in_block || (i + 1) == child_blocks.size()) {
                // LABEL SIMPLE COND -> IF [ P_LAB && P0 ] ( SIMPLE COND ) FI 
                // SIMPLE COND -> IF [ P0 ] ( SIMPLE COND ) FI
                // note for next : LABEL2 isn't the current command
                // LABEL1 SIMPLE LABEL2 -> IF [ P_LAB && P0 ] ( SIMPLE ) FI LABEL2 
                unsigned begin = 0;
                unsigned end = 0;
                for (unsigned j = 0; j < parent->get_num_children(); ++j) {
                    if (parent->get_child(j) == child_blocks[block_begin].comms.back()) {
                        begin = j;
                    } 
                    if (parent->get_child(j) == child_blocks[i].comms.back()) {
                        end = j;
                    }
                }                        
                block new_block = generate_hidden_if(child_blocks.begin() +
                        block_begin, child_blocks.begin() + i,
                        shared_var);
                new_block.comms.back()->clear_args();
                new_block.comms.back()->add_string(shared_var);
                new_block.comms.back()->add_string("==");
                new_block.comms.back()->add_string("1");
                if (label != 0) {
                    new_block.comms.back()->add_string("||");
                    new_block.comms.back()->add_string(shared_var);
                    new_block.comms.back()->add_string("==");
                    new_block.comms.back()->add_string(toString(label));
                }
                child_blocks.erase(child_blocks.begin() + block_begin
                        ,i + child_blocks.begin() + 1);
                child_blocks.insert(child_blocks.begin() + block_begin,
                        new_block);
                parent->remove_children(begin, end);
                parent->insert_child(begin, new_block.comms.back());
                i = block_begin++;  
                if (label) {
                    child_labels.erase(child_labels.begin());
                }
                in_block = false;
                label = 0;
            }
        }
        command* set_comm = new command("set", parent->get_line());
        set_comm->add_string(shared_var);
        set_comm->add_string("=");
        set_comm->add_string("0");
        block set_block(set_comm);
        command* if_comm = new command("if", parent->get_line());
        command* compound_comm = new command("compound", parent->get_line());
        if_comm->add_child(compound_comm);
        compound_comm->add_child(set_comm);
        if_comm->add_string(shared_var);
        if_comm->add_string("==");
        if_comm->add_string("1");
        block if_block(if_comm);
        block compound_block(compound_comm);
        for (unsigned i = 0; i < child_jumps.size(); ++i) {
            for (unsigned j = 0; j < child_jumps[i].size(); ++j) {
                if (label_predicate.find(child_jumps[i][j]->label) !=
                        label_predicate.end()) {
                    std::string str = child_jumps[i][j]->predicate_command->get_argument
                        (child_jumps[i][j]->predicate_command->get_num_args() - 1).value;
                    int num = fromString<int>(str);
                    if (find(jumps_out.begin(), jumps_out.end(), num) == jumps_out.end()) {
                        child_jumps[i].erase(child_jumps[i].begin() + j);
                        j--;
                    } else {
                        if_comm->add_string("||");
                        if_comm->add_string(shared_var);
                        if_comm->add_string("==");
                        if_comm->add_string(toString(num));
                        set_comm = new command("set", parent->get_line());
                        set_comm->add_string(shared_var);
                        set_comm->add_string("=");
                        set_comm->add_string(toString(num));
                        child_jumps[i][j]->predicate_command = set_comm;
                        compound_comm->add_child(set_comm);
                        compound_block.child_blocks.push_back(block(set_comm));
                    }
                }
            }
        }
        if_block.child_blocks.push_back(compound_block);
        child_blocks.push_back(if_block);
        parent->add_child(if_comm);
        block new_block = generate_hidden_while(child_blocks.begin(), 
                child_blocks.begin() + child_blocks.size() - 1,
                shared_var);
        new_block.comms.back()->clear_args();
        new_block.comms.back()->add_string(shared_var);
        new_block.comms.back()->add_string("!=");
        new_block.comms.back()->add_string("0");
        child_blocks.clear();
        child_blocks.push_back(new_block);
        parent->remove_children(0, parent->get_num_children() - 1); 
        parent->add_child(new_block.comms.back());
    }

    ret.child_blocks = child_blocks;
	for (std::vector<std::vector<jump*> >::iterator i = child_jumps.begin();
            i != child_jumps.end(); ++i) {
		for (std::vector<jump*>::iterator j = i->begin(); j != i->end(); ++j) {
			ret.child_jumps.push_back(*j);
		}
	}
    if (child_labels.size() > 0) { // there are some child_labels in this block to which no jump has been performed to
        ret.type = bHARD;
    } else if (ret.child_jumps.size() > 0) {
        ret.type = bCOND;
    } else {
        ret.type = bSIMPLE;
    }
    return ret;        
}

struct tree_frame {
    command* com;
    unsigned visited;
    tree_frame(command* com, unsigned visited = 0) : com(com), visited(visited) { }
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

bool program::convert_goto() {
    block ret = recursive_conv_goto(root, this);
    print_vars();
    if (ret.type == bHARD) { 
        fprintf(stderr, "not possible to convert goto");
        return false;
    }
    return true;
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
    for (unsigned i = 0; i < labels.size(); ++i) {
        if (labels[i].name == name) {
            return labels[i];
        }
    }
    throw std::logic_error("label doesn't exist: " + name);
    //return *(find(labels.begin(), labels.end(), label(name, 42)));
}

label& label_list::get_label(const std::string& name) {
    for (unsigned i = 0; i < labels.size(); ++i) {
        if (labels[i].name == name) {
            return labels[i];
        }
    }
    throw std::logic_error("label doesn't exist: " + name);
    //return *(find(labels.begin(), labels.end(), label(name, 42)));
}


const jump& jump_list::get_jump(int line) const {
    for (unsigned i = 0; i < jumps.size(); ++i) {
        if (jumps[i].line == line) {
            return jumps[i];
        }
    }
    throw std::logic_error("jump doesn't exist on line: " + toString(line));
}

jump& jump_list::get_jump(int line) {
    for (unsigned i = 0; i < jumps.size(); ++i) {
        if (jumps[i].line == line) {
            return jumps[i];
        }
    }
    throw std::logic_error("jump doesn't exist on line: " + toString(line));
}

jump& jump_list::get_jump(const std::string& label) {
    for (unsigned i = 0; i < jumps.size(); ++i) {
        if (jumps[i].label == label) {
            return jumps[i];
        }
    }
    throw std::logic_error("jump doesn't with that label: " + label);
}

const jump& jump_list::get_jump(const std::string& label) const {
    for (unsigned i = 0; i < jumps.size(); ++i) {
        if (jumps[i].label == label) {
            return jumps[i];
        }
    }
    throw std::logic_error("jump doesn't with that label: " + label);
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
    for (unsigned i = 0; i < vars.size(); ++i) {
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
    for (unsigned i = 0; i < vars.size(); ++i) {
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
program::~program() {
    if (root != NULL) {
        delete root;
    }
}
