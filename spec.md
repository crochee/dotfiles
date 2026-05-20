- superpowers : git@github.com:obra/superpowers.git
- OpenSpec : git@github.com:Fission-AI/OpenSpec.git
- openspec-schemas : git@github.com:JiangWay/openspec-schemas.git
- wiki : git@github.com:Astro-Han/karpathy-llm-wiki.git
- rule : git@github.com:multica-ai/andrej-karpathy-skills.git


```json
{
  "allow": [
    "Read",
    "Write",
    "Edit",
    "WebSearch",
    "WebFetch",
    "Mcp*",
    "Bash(*)"
  ],
  "ask": ["Bash(sudo *)", "Bash(rm *)", "Bash(chmod *)", "Bash(chown *)"],
  "deny": ["Bash(/)", "Bash(/etc)", "Bash(/System)"]
}
```
