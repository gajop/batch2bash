#include "semantic.h"
#include <stdexcept>
#include <algorithm>
#include <stack>

struct block {
    std::vector<block*> child_blocks;
    std::vector<jumps> child_jumps;
    command comm;
    enum type { SIMPLE, COND, HARD };
    block(const command& comm) : comm(comm) {}
    block operator +(const block& lhs, const block& rhs);
};

block block::operator +(const block& lhs, const block& rhs) {
    block ret(lhs);
    ret.insert(ret.end(), rhs.begin(), rhs.end());
    ret.type = SIMPLE; // right?
    return ret;
}

block* translate(command* parent) {
    block* ret = new block(*parent);
    if (parent->commands.empty()) {
        if (parent->type == JUMP) { 
            ret->type = COND;
        } else if (parent->type == LABEL) {
            ret->type = LABEL;
        } else {
            ret->type = SIMPLE;
        }
        return ret;
    }
    std::vector<block*> child_blocks;
    std::vector<label> labels;
    std::vector<jumps> child_jumps; //recursively
    block* result;
    for (std::vector<command*>::iterator i = parent->begin(); i != parent->end(); ++i) {
        result = translate(&(*i));
        switch (result->type) {
            case SIMPLE :
                if (!child_blocks.empty() && (*child_blocks.last()) == SIMPLE) {
                    (*child_blocks.last()) += *result;
                    // simple_block : simple_block simple_block;
                } else {
                    child_blocks.push_back(result);
                }
                break;
            case COND : 
                child_blocks.push_back(*result);
                child_jumps.push_back(result->child_jumps);
                for (int i = 0; i < result->child_jumps.size(); ++i) {
                    conds.push_back(result->child_jumps[i]);
                }
                break;
            case HARD :
                // scream recursively ;)
                break;
            case LABEL : // just one label, in no block
                child_block.push_back(result);
                labels.push_back(result);
                break;
        }
    }

    // first find all hidden loops and convert them to simple blocks
    int label_counter = jump_counter = 0;
    int line = -1;
    enum s_type = { NONE = -1, LABEL, JUMP };
    struct previous {
        s_type type = NONE;
        std::vector<block>::iterator pos;
        previous(s_type type, std::vector<block>::iterator pos) : type(type), pos(pos) {}
    };
    std::stack<previous> prev;
    for (std::vector<block>::iterator i = child_blocks.begin(); i != child_blocks.end(); ++i) {
        line = i->line;
        if (label_counter < labels.size() && line == labels[label_counter].line) {
            if (labels[label_counter].jumps.size() == 1 && prev.top().type == JUMP &&
                    jumps[jump_counter - 1].size() == 1 &&
                    labels[label_counter].jumps.front() == jumps[jump_counter - 1].front()) {
                // COND1 SIMPLE* LABEL1 -> COND1 IF!1 SIMPLE* FI!1
                block new_block = generate_hidden_if(prev.top().pos, i);
                child_blocks.erase(prev.top().pos + 1, ++i);
                *(prev.top().pos) = new_block;
                labels.erase(labels.begin() + label_counter);
                jumps.erase(jumps.begin() + jump_counter - 1);
                prev.pop();
            } else {
                prev.push(previous(LABEL, i));
                ++label_counter;
            }
        } else if (jump_counter < jumps.size() && line == jumps[jump_counter].line) {
            if (jumps[jump_counter].size() == 1 && prev.top().type == LABEL &&
                    labels[label_counter - 1].jumps.size() == 1 && 
                    labels[label_counter - 1].jumps.front() == jumps[jump_counter].front()) {
                // LABEL1 SIMPLE* COND1 -> WHILE1 SIMPLE* COND1 DONE
                block new_block = generate_hidden_while(prev.top().pos, i);
                child_blocks.erase(prev.top().pos + 1, ++i);
                *(prev.top().pos) = new_block;
                labels.erase(labels.begin() + label_counter - 1);
                jumps.erase(jumps.begin() + jump_counter);
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
        ret->type = HARD;
    } else if (child_jumps.size() > 0) {
        ret->type = COND;
    } else {
        ret->type = SIMPLE;
    }
    return ret;        
}

void program::generate_bash() {
    label_list unused = labels;
    // read the info file, all the documentation is there
    for (int i = 0; i < goto_commands.size(); i++) {
        if (unused.label_exists(commands[i].jump_dest)) {
            unused.label_remove(commands[i].jump_dest);
        } else {
            throw std::logic_error("jump to an unknown label");
        }
    }
    for (std::set<string> i = unused.unused().begin(); i < unused.unused().end(); ++i) {
        labels.remove(*i);
    }
    block ret = translate(commands.first());
}

bool label_list::label_exists(const std::string& label) const {
    if (labels.find(label) != labels.end()) {
        return false;
    }
    return true;
}

void label_list::add_label(const label& label) {
    if (labels.find(label) != labels.end()) {
        labels.insert(label);
    } else {
        throw std::logic_error("label already exists"); 
    }
}

void label_list::remove_label(const std::string& label) {
    if (!labels.erase(label))
        throw std::logic_error("label doesn't exists"); 
    }
}
unsigned label_list::num_labels() const {
    return labels.size();
}
