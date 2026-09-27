-- 项目根标记: project.nvim 的 patterns 与 trouble todo_project 源共用,
-- 保证「切项目」与「项目级 todo 搜索」判定同一个根.
return { ".git", "pom.xml", "*.csproj", "Makefile", "Cargo.toml", "go.mod", "package.json", "pyproject.toml" }
