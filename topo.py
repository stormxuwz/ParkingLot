import numpy as np

def get_node_id(row, column, i,j):
	return column*(i-1)+j

def transform_parkinglot(x,y):
	row = 2*x-1
	column = 3*y+1
	M = np.zeros((row,column))
	for i in range (1,row+1):
		for j in range(1, column+1):
			M[i-1][j-1] = get_node_id(row,column,i,j)

	return M  


def generate_neighbor_list(M):
	row = M.shape[0]
	column = M.shape[1]
	all_neighbors = []
	node_ids = []

	for i in range(1, row+1):
		for j in range(1, column+1):
			node_id = get_node_id(row,column,i,j)
			node_neigbor=[]
			if ( i%2 == 0 and j >= 4 and (j-1)%3 == 0): 
				# add surrounding 4 parking lots
				node_neigbor.append(get_node_id(row,column,i-1,j-1))
				node_neigbor.append(get_node_id(row,column,i+1,j-1))
				if (j < column):
					node_neigbor.append(get_node_id(row,column,i-1,j+1))
					node_neigbor.append(get_node_id(row,column,i+1,j+1))
				# add upward
				if (i < row-2):
					node_neigbor.append(get_node_id(row,column,i+2,j))
				# add leftward
				if (j < column-2):
					node_neigbor.append(get_node_id(row,column,i,j+3))
				#add downward
				if (i>3):
					node_neigbor.append(get_node_id(row,column,i-2,j))

				all_neighbors.append(node_neigbor)
				node_ids.append(node_id)


	# print "list:",all_neighbors;
	# print "index:",node_ids;
	return node_ids, all_neighbors

def write_to_file(node_ids,all_neighbors,output):
	with open(output, 'w') as out_file:
		for node,neighbors in enumerate(all_neighbors):
			for neighbor in neighbors:
				out_file.write(str(neighbor) + " " + str(node_ids[node]) + " -50\n")


if __name__ == "__main__":
	M = transform_parkinglot(5,3) 
	print M.shape;
	node_ids, all_neighbors = generate_neighbor_list(M)
	write_to_file(node_ids,all_neighbors,"text.txt")

	
