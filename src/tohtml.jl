include("ify.jl")

function makehtml(pathv::Vector,tree::Dict,tree_str;
	charset::String="UTF-8",
	md::Union{Tuple{String,String},Nothing}=nothing,
	lang::String="zh",
	path::String,
	repo::String="https://github.com/JuliaRoadmap/zh/",
	tURL::String="../"^length(pathv))
	if md===nothing
		io=open(path,"r")
		try
			mds,title=md_withtitle(read(io,String))
		catch er
			buf=IOBuffer()
			showerror(buf,er)
			mds="<p>ERROR: $(ify_s(String(take!(buf))))</p>"
		end
		close(io)
	else
		mds,title=md
	end
	docs_menu=""
	navbar_title=""
	editpath= last(pathv)=="index" ? repo*path[1:end-5]*"setting.toml" : repo*path
	prevpage=""
	nextpage=""
	return """
	<!DOCTYPE html>
	<html lang="$lang">
	<head>
		<meta charset="$charset"/>
		<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
		<title>$title</title>
		<meta name="tURL" id="tURL" content="$tURL"/>
		<script src="https://cdnjs.cloudflare.com/ajax/libs/require.js/2.3.6/require.min.js" data-main="$(tURL)js/main.js"></script>
		<link id="theme-href" rel="stylesheet" type="text/css">
		<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.0/css/fontawesome.min.css"/>
		<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.0/css/solid.min.css"/>
		<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.0/css/brands.min.css"/>
	</head>
	<body>
		<div id="documenter">
			<nav class="docs-sidebar">
				<a class="docs-logo"><img src="$(tURL)img/logo.png" alt="alt" height="96" width="144"></a>
				<div class="docs-package-name">
				<span class="docs-autofit">JuliaRoadmap</span>
				</div>
				<ul class="docs-menu">$docs_menu</ul>
			</nav>
			<div class="docs-main">
				<header class="docs-navbar">
					<nav class="breadcrumb">
						<ul class="is-hidden-mobile"><li class="is-active">$navbar_title</li></ul>
						<ul class="is-hidden-tablet"><li class="is-active">$navbar_title</li></ul>
					</nav>
					<div class="docs-right">
						<a class="docs-edit-link" title="编辑" href="$editpath">
							<span class="docs-label is-hidden-touch">编辑此页面</span>
						</a>
						<a class="docs-settings-button fas fa-cog" id="documenter-settings-button" href="#" title="设置"></a>
						<a class="docs-sidebar-button fa fa-bars is-hidden-desktop" id="documenter-sidebar-button" href="#"></a>
					</div>
				</header>
				<article class="content">$mds</article>
				<nav class="docs-footer">$(prevpage)$(nextpage)</nav>
			</div>
			<div class="modal" id="documenter-settings">
				<div class="modal-background"></div>
				<div class="modal-card">
					<header class="modal-card-head">
						<p class="modal-card-title">设置</p>
						<button class="delete"></button>
					</header>
					<section class="modal-card-body">
						<p><label class="label">选择主题</label>
							<div class="select">
								<select id="documenter-themepicker">
									<option value="light">亮色</option><option value="dark">暗色</option>
								</select>
							</div>
						</p>
					</section>
					<footer class="modal-card-foot"></footer>
				</div>
			</div>
		</div>
	</body>
	</html>
	"""
end
