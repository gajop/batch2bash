#include "semantic.h"
#include <stdexcept>
#include <algorithm>
#include <stack>

enum block_type { bSIMPLE, bCOND, bLABEL, bHARD };

struct block {
    std::vector<block*> child_blocks;
    std::vector<jump> child_jumps;
    command comm;
    block_type type;
    block(const command& comm) : comm(comm) {}
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
block* translate(command* parent, program* shared_program) {
    block* ret = new block(*parent);
    if (parent->commands.empty()) {
        if (parent->type == cJUMP) { 
            ret->type = bCOND;
            ret->jmplabel.jmp = &shared_program->jumps.get_jump(parent->line);
        } else if (parent->type == cLABEL) {
            ret->type = bLABEL;
            ret->jmplabel.labl = &shared_program->labels.get_label(parent->name);
        } else {
            ret->type = bSIMPLE;
        }
        return ret;
    }
    std::vector<block*> child_blocks;
    std::vector<label> labels;
    std::vector<std::vector<jump> > child_jumps; //recursively
    block* result;
    for (std::vector<command>::iterator i = parent->commands.begin(); 
            i != parent->commands.end(); ++i) {
        result = translate(&(*i), shared_program);
        switch (result->type) {
            case bSIMPLE :
                if (!child_blocks.empty() && child_blocks.back()->type == bSIMPLE) {
                    *(child_blocks.back()) = *(child_blocks.back()) + *result;
                    // simple_block : simple_block simple_block;
                } else {
                    child_blocks.push_back(result);
                }
                break;
            case bCOND : 
                child_blocks.push_back(result);
                child_jumps.push_back(result->child_jumps);
                break;
            case bHARD :
                // scream recursively ;)
                break;
            case bLABEL : // just one label, in no block
                child_blocks.push_back(result);
                labels.push_back(*(result->jmplabel.labl));
                break;
        }
    }

    // first find all hidden loops and convert them to simple blocks
    int label_counter = 0, jump_counter = 0;
    int line = -1;
    std::stack<previous> prev;
    for (std::vector<block*>::iterator i = child_blocks.begin(); i != child_blocks.end();
            ++i) {
        line = (*i)->comm.line;
        if (label_counter < labels.size() && line == labels[label_counter].line) {
            if (labels[label_counter].jumps.size() == 1 && prev.top().type == JUMP &&
                    child_jumps[jump_counter - 1].size() == 1 &&
                    labels[label_counter].jumps.count(child_jumps[jump_counter - 1].front())) {
                // COND1 SIMPLE* LABEL1 -> COND1 IF!1 SIMPLE* FI!1
                //block new_block = generate_hidden_if(prev.top().pos, i);
                child_blocks.erase(prev.top().pos + 1, i++);
                *(prev.top().pos) = new_block;
                labels.erase(labels.begin() + label_counter);
                child_jumps.erase(child_jumps.begin() + jump_counter - 1);
                prev.pop();
            } else {
                prev.push(previous(LABEL, i));
                ++label_counter;
            }
        } else if (jump_counter < child_jumps.size() && line == child_jumps[jump_counter].line) {
            if (child_jumps[jump_counter].size() == 1 && prev.top().type == LABEL &&
                    labels[label_counter - 1].jumps.size() == 1 && 
                    labels[label_counter - 1].jumps.front() == child_jumps[jump_counter].front()) {
                // LABEL1 SIMPLE* COND1 -> WHILE1 SIMPLE* COND1 DONE
                block new_block = generate_hidden_while(prev.top().pos, i);
                child_blocks.erase(prev.top().pos + 1, ++i);
                *(prev.top().pos) = new_block;
                labels.erase(labels.begin() + label_counter - 1);
                child_jumps.erase(child_jumps.begin() + jump_counter);
                prev.pop();
            } else {
                prev.push(previous(JUMP, i));
                ++jump_counter;
            }
        }
    }
/* 
 *  LEAVING MULTIJUMPS FOR LATER... first test this
    // now if there are any remaining labels and corresponding jumps enclose it all in a big while loop and put ifs inside
    for (int i = 0; i < child_blocks.size(); ++i) {

    }
*/
    ret.child_blocks = child_blocks;
    ret.child_jumps = child_jumps;
    if (labels.size() > 0) { // there are some labels in this block to which no jump has been performed to
        ret->type = bHARD;
    } else if (child_jumps.size() > 0) {
        ret->type = bCOND;
    } else {
        ret->type = bSIMPLE;
    }
    return ret;        
}

void program::done() { 
    for (std::vector<jump>::iterator i = jumps.begin(); i != jumps.end(); ++i) {
        add_jump(*i);
    } 
    label_list unused = labels;
    // read the info file, all the documentation is there
    for (int i = 0; i < jumps.size(); i++) {
        if (unused.label_exists(jumps.label)) {
            unused.label_remove(jumps.label);
        } else {
            throw std::logic_error("jump to an unknown label");
        }
    }
    for (std::set<string> i = unused.unused().begin(); i < unused.unused().end(); ++i) {
        labels.remove(*i);
    }
}

void program::generate_bash() {
    block ret = translate(commands.first());
}

bool label_list::label_exists(const std::string& label) const {
    for (std::set<label>::iterator i = labels.begin(); i != labels.end(); ++i) {
        if (i->name == label) {
            return true;
        }
    }
    return false;
}

void label_list::add_label(const std::string& name, int line) {
    for (std::set<label>::iterator i = labels.begin(); i != labels.end(); ++i) {
        if (i->name == label) {
            throw std::logic_error("label already exists"); 
        }
    }
    labels.insert(label(name, line));
}

void label_list::remove_label(const std::string& label) {
    if (!labels.erase(label))
        throw std::logic_error("label doesn't exists"); 
    }
}
unsigned label_list::num_labels() const {
    return labels.size();
}

void label_list::add_jump(const jump& jmp) {
    std::set<label>::iterator lab = labels.find(jmp.label)
    if (lab == labels.end())
        throw std::logic_error("label doesn't exists"); 
    } 
    if (lab.jumps.find(jmp) == lab.jumps.end()) {
        lab.jumps.insert(jmp);
    }
}
