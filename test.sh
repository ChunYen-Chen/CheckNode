# 1. The original
echo "********************* Original ********************"
sh check_node.sh

# 2. Single option
echo "********************* Option a ********************"
sh check_node.sh -a
echo "********************* Option f ********************"
sh check_node.sh -f
echo "********************* Option d ********************"
sh check_node.sh -d
echo "********************* Option o ********************"
sh check_node.sh -o
echo "********************* Option h ********************"
sh check_node.sh -h
echo "********************* Option i ********************"
sh check_node.sh -i
echo "********************* Option j ********************"
sh check_node.sh -j
echo "********************* Option q ********************"
sh check_node.sh -q
echo "********************* Option t ********************"
sh check_node.sh -t

# 3. Multi options
echo "********************* Option ij *******************"
sh check_node.sh -ij
echo "********************* Option jt *******************"
sh check_node.sh -jt
echo "********************* Option at *******************"
sh check_node.sh -at
echo "********************* Option af *******************"
sh check_node.sh -af
echo "********************* Option ftj ******************"
sh check_node.sh -ftj

# 4. Conflit options
echo "********************* Option hq *******************"
sh check_node.sh -hq
echo "********************* Option iq *******************"
sh check_node.sh -iq
echo "********************* Option hi *******************"
sh check_node.sh -hi
