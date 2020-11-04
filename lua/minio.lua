
  
function download(pathurl,filepath)

	local sock= ngx.socket.tcp();
	sock:settimeout(3000)
	sock:setkeepalive(5000)
	local ok, err = sock:connect("your server IP", "9000")  
	local bytes, err = sock:send("GET "..pathurl.." HTTP/1.1\r\nConnection:close\r\nHost:your server IP:9000\r\n\r\n")
	if not bytes then
				ngx.log(ngx.ERR, "send request error:" .. err)
				sock:close()
				ngx.log(ngx.ERR,'socket closed') 
				ngx.exit(500) 
		  end 
		    ngx.log(ngx.ERR,'begin read') 
			local line, name, value, err
			headers = {}
			line, err = sock:receive()
			if err then return nil, err end
			-- headers go until a blank line is found
			while line ~= "" do  
				line, err  = sock:receive()
				if err then ngx.log( ngx.ERR,err.."\n") break end
				name,value =string.find(line, "^(.-):%s*(.*)")
				ngx.log(ngx.ERR,line.."---\n")
				-- unfold any folded values  
				while string.find(line, "^%s") do 
					line,err = sock:receive() 
					ngx.log(ngx.ERR,line.."\n")
					if err then ngx.log( ngx.ERR,"break"..err.."\n")  break end
				end
				-- save pair in table
				 
			end
			ngx.log(ngx.ERR,"Save To:"..filepath.."\n")
		    
			file = io.open(filepath, "wb"); 
			if (file) then
				 
				   local data, err, partial = sock:receive('*a')    
				   if(data or partial) then 
						file:write(data or partial);  
				   end  
				   
				   file:close() 
			end
			
		    sock:close() 

end
 

local function is_dir(sPath)
    if type(sPath) ~= "string" then return false end

    local response = os.execute( "cd " .. sPath )
    if response == 0 then
        return true
    end
    return false
end

local file_exists = function(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
end


local image_sizes = {"80x80", "800x600", "40x40", "60x60","20x20","392x392","800x800","240x240","200x200","364x230","350x240","270x270","230x230","214x214","215x215"};

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return true
end

ngx.log(ngx.ERR,ngx.var.uri)

local area = nil
local originalUri = ngx.var.uri;
local originalFile = ngx.var.originalFile;
local file=ngx.var.file
--local index = findLast(ngx.var.uri, "([0-9]+)x([0-9]+)"); 

local index = string.find(ngx.var.uri, "([0-9]+)x([0-9]+)"); 

if index then
    originalUri = string.sub(ngx.var.uri, 0, index-2);  
	  --ngx.log(ngx.ERR,'orifile:'..originalFile.."\n")
    area = string.sub(ngx.var.uri, index);
    index = string.find(area, "([.])");
    area = string.sub(area, 0, index-1); 
	  --ngx.log(ngx.ERR,'area:'..area.."\n")
    local index = string.find(originalFile, "([0-9]+)x([0-9]+)");
	  --ngx.log(ngx.ERR,'orifile:'..originalFile.."\n")
    originalFile = string.sub(originalFile, 0, index-2)  
end 

  ngx.log(ngx.ERR,'orifile:'..originalFile.."\n")--images/orders.png
   
-- check original file
if not file_exists(ngx.var.file) then 
    -- main
          if not is_dir(ngx.var.image_dir) then
		   
		     -- ngx.log(ngx.ERR,'mkdir:'.. ngx.var.image_dir.."\n")
              os.execute("mkdir  " .. ngx.var.image_dir)
			  
          end  
		  local miniourl=originalFile 
		 -- ngx.log(ngx.ERR,'miniourl:'..miniourl.."\n")
		  download(miniourl,ngx.var.file)
		  
		  if index  then
		   
			  local command = "gm convert  ." .. originalFile  .. " -thumbnail " .. area .. " -background gray -gravity center -extent " .. area .. " " .. ngx.var.file
			 -- ngx.log(ngx.ERR,command.."\n")
			  os.execute(command); 
		   end
		 
end 
if file_exists(ngx.var.file) then 
     --ngx.log(ngx.ERR,("uri:"..ngx.var.uri.."\n")) 
     --ngx.req.set_uri(ngx.var.uri, true); 
     ngx.exec(ngx.var.uri)  
else
    ngx.exit(404)
end

