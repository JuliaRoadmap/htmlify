include("ify.jl")
function makehtml(path::String,tURL::String;charset::String="UTF-8",lang::String="zh")
	io=open(path,"r")
	mds=ify_md(read(io,String))
	close(io)
	return """
	<!DOCTYPE html>
	<html lang="$lang">
	<head>
		<meta charset="$charset"/>
		<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
		<title>标题</title>
		<meta name="tURL" id="tURL" content="$tURL"/>
		<script src="https://cdnjs.cloudflare.com/ajax/libs/require.js/2.3.6/require.min.js" data-main="$(tURL)js/main.js"></script>
		<link id="theme-href" rel="stylesheet" type="text/css">
		<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.0/css/fontawesome.min.css"/>
		<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.0/css/solid.min.css"/>
		<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.0/css/brands.min.css"/>
	</head>
	</html>
	"""
end
