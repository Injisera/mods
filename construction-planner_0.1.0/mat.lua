local matrix = {}
--require("util")

function matrix.print(mat)
  for _,row in ipairs(mat) do
    local str = ""
    for c,cell in ipairs(row) do
      if c>1 then str = str .. ", " end
      str = str .. tonumber(string.format("%.3f", cell))
    end
    game.print(str)
  end
end

function matrix.sq(val)
  return val*val
end

function matrix.inv(mat)--assuming input is a square matrix, gaussian elimination
  local A = {}
  local rows = #mat

  for n = 1,rows do
    A[n] = {}

    for m = 1,rows do -- copy mat
      A[n][m]=mat[n][m]
    end

    for m = 1,rows do -- append eye to right of mat
      A[n][m+rows] = 0
    end
    A[n][n+rows] = 1
  end
  --we got (mat|eye)

  for n=1,rows do
    local x = n+1
    --always place the highest magnitude in the specific column we're on to the right row
    
    local max = 0
    local index = 1

    for i=n,rows do
      local val = matrix.sq(A[i][n])
      if matrix.sq(A[i][n])>max then
        max = val
        index = i
      end
    end

    if max==0 then --if there's no viable element below... then uhhhhh.... let's just say we failed
      return nil
    end


    -- do the swap
    local temp = A[index]
    A[index] = A[n]
    A[n] = temp

    --doing this swap is faster than doing an if statement to see if we should swap
    --yes, swapping with itself is faster than checking if we should swap with itself and not swap
    
    --we are now ready to make everything zero below us!
    for i=x,rows do
      if A[i][n]~=0 then --if the element is 0 then there's no need for us to mess with it
        local fraction = A[i][n]/A[n][n]
        for m=x,rows*2 do
          A[i][m] = A[i][m]-A[n][m]*fraction
        end
      end
    end
  end

  for n = rows-1,1,-1 do--make everything above us 0
    local x = n+1
    for i = n,1,-1 do    
      if A[i][x]~=0 then
        local fraction = A[i][x]/A[x][x]
        for m = 1,rows do --only mess with the eye
          A[i][m+rows] = A[i][m+rows]-A[x][m+rows]*fraction
        end
      end
    end
  end

  

  --normalize the diagonal so the right hand is the inverse
  local output = {}
  for n = 1,rows do
    output[n] = {}
    for m = 1,rows do
      output[n][m] = A[n][m+rows]/A[n][n]
    end
  end

  return output
end



function matrix.AB(A,B)--A transpose times B
  local output = {} -- make a new matrix
  local rows = #A       --get rows of A, our new height
  local length = #B     --get common length, #A[1] = #B
  local columns = #B[1] --get columns of B, our new width
  
  for n=1,rows do
    output[n] = {} -- make it a 2D array
    for m=1,columns do
      local sum = 0
      for i=1,length do
        sum = sum + A[n][i]*B[i][m]
      end
      output[n][m]=sum
    end
  end
  return output
end

function matrix.Ab(A,b)--A times b (matrix * vector)
  local output = {} -- make a new matrix
  local rows = #A       --get rows of A, our new height
  local length = #b     --get common length, #A[1] = #B
  for n=1,rows do
    local sum = 0
    for m=1,length do
      sum = sum + A[n][m]*b[m]
    end
    output[n]=sum
  end
  return output
end

function matrix.AtB(A,B)--A times B, assume input is safe to use, there are no safety checks in here!
  local output = {} -- make a new matrix
  local rows = #A[1]    --get rows of A, our new height, first row that is differemt from AB
  local length = #B     --get common length, #A[1] = #B
  local columns = #B[1] --get columns of B, our new width
  
  for n=1,rows do
    output[n] = {} -- make it a 2D array
    for m=1,columns do
      local sum = 0
      for i=1,length do
        sum = sum + A[i][n]*B[i][m]--second row that is different from AB
      end
      output[n][m]=sum
    end
  end
  return output
end

function matrix.ABt(A,B)--A times B transpose
  local output = {} -- make a new matrix
  local rows = #A[1]    --get rows of A, our new height, first row that is differemt from AB
  local length = #B     --get common length, #A[1] = #B
  local columns = #B[1] --get columns of B, our new width
  
  for n=1,rows do
    output[n] = {} -- make it a 2D array
    for m=1,columns do
      local sum = 0
      for i=1,length do
        sum = sum + A[n][i]*B[m][i]--second row that is different from AB
      end
      output[n][m]=sum
    end
  end
  return output
end

function matrix.AAt(A)--A times B transpose
  local output = {} -- make a new matrix
  local rows = #A    --get rows of A, our new height, first row that is differemt from AB
  local length = #A[1]
  for n=1,rows do
    output[n] = {} -- make it a 2D array
    for m=1,rows do
      local sum = 0
      for i=1,length do
        sum = sum + A[n][i]*A[m][i]--second row that is different from AB
      end
      output[n][m]=sum
    end
  end
  return output
end

--[[


local debug_A' = {
  {45.0/5.0,    0,               0},
  {55.0/5.0,    45.0/5.0,        25.0/5.0},
}

local debug_A = {
  {45.0/5.0,    55.0/5.0},
  {0,           45.0/5.0},
  {0,           25.0/5.0}
}
--]]


function matrix.AtA(A)--A times B transpose
  local output = {} -- make a new matrix
  local rows = #A[1]     --get common length, #A[1] = #B
  local length = #A
  for n=1,rows do
    output[n] = {} -- make it a 2D array
    for m=1,rows do
      local sum = 0
      for i=1,length do
        sum = sum + A[i][n]*A[i][m]--second row that is different from AB
      end
      output[n][m]=sum
    end
  end
  return output
end


function matrix.Atb(A,b)--A transpose matrix times vector b
  local output = {} -- make a new matrix
  local rows = #A[1]    --get rows of A, our new height
  for n=1,rows do
    local sum = 0
    for m=1,rows do
      sum = sum + A[m][n]*b[m]
    end
    output[n]=sum
  end
  return output
end



return matrix