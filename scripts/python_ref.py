import numpy as np

def mat_vec_mul(matrix, vector):
    matrix = np.array(matrix, dtype=np.int8) #8 bit matrix
    vector = np.array(vector, dtype=np.int8) #8 bit vector
    return matrix.astype(np.int32) @ vector.astype(np.int32) #dot product

#tests
#identity matrix
matrix1 = [[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]
vector1 = [1,2,3,4]
print("test 1: ", mat_vec_mul(matrix1, vector1))  # [1,2,3,4]

#all ones 
matrix1 = [[1,1,1,1],[1,1,1,1],[1,1,1,1],[1,1,1,1]]
vector1 = [1,1,1,1]
print("test 2: ", mat_vec_mul(matrix1, vector1))  # [4,4,4,4]

#negative weights
matrix1 = [[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1]]
vector1 = [1,1,1,1]
print("test 3: ", mat_vec_mul(matrix1, vector1))  # [-4,-4,-4,-4]