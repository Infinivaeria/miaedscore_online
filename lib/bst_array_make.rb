# A class to store a binary tree node
class Node:
  def __init__(self, key):
      self.key = key


# Recursive function to perform inorder traversal on a given binary tree
def inorder(root):

  if root is None:
      return

  inorder(root.left)
  print(root.key, end=' ')
  inorder(root.right)


# Recursive function to build a binary search tree from
# its postorder sequence
def constructBST(postorder, start, end):

  # base case
  if start > end:
      return None

  # Construct the root node of the subtree formed by keys of the
  # postorder sequence in range `[start, end]`
  node = Node(postorder[end])

  # search the index of the last element in the current range of postorder
  # sequence, which is smaller than the root node's value
  i = end
  while i >= start:
      if postorder[i] < node.key:
          break
      i = i - 1

  # Build the right subtree before the left subtree since the values are
  # being read from the end of the postorder sequence.

  # recursively construct the right subtree
  node.right = constructBST(postorder, i + 1, end - 1)

  # recursively construct the left subtree
  node.left = constructBST(postorder, start, i)

  # return current node
  return node


if __name__ == '__main__':

  ''' Construct the following BST
            15
          /    \
         /      \
        10       20
       /  \     /  \
      /    \   /    \
     8     12 16    25
  '''

  postorder = [8, 12, 10, 16, 25, 20, 15]

  # construct the BST
  root = constructBST(postorder, 0, len(postorder) - 1)

  # print the BST
  print('Inorder traversal of BST is ', end='')

  # inorder on the BST always returns a sorted sequence
  inorder(root)