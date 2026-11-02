**Load this reference when:** searching for papers, checking a citation graph, or pulling a paper's
metadata. It holds the arXiv and Semantic Scholar recipes, the rate limits, and the traps.

# Academic sources

Two free APIs carry most of the paper route. Neither needs a key for the basic calls, and both have
a limit worth knowing before the run starts.

## arXiv REST API

```bash
curl -s "https://export.arxiv.org/api/query?search_query=all:reinforcement+learning&max_results=5"
curl -s "https://export.arxiv.org/api/query?id_list=1706.03762"
curl -s "https://export.arxiv.org/api/query?search_query=cat:cs.AI&sortBy=submittedDate&sortOrder=descending&max_results=10"
```

### Query prefixes

| Prefix | Searches | Example |
|---|---|---|
| `all:` | every field | `all:transformer+attention` |
| `ti:` | title | `ti:large+language+models` |
| `au:` | author | `au:hinton` |
| `abs:` | abstract | `abs:reinforcement+learning` |
| `cat:` | category | `cat:cs.AI` |
| `co:` | comment | `co:accepted+NeurIPS` |

### Boolean operators

```text
all:transformer+attention              AND (the default)
all:GPT+OR+all:BERT                     OR
all:language+model+ANDNOT+all:vision   AND NOT
ti:"chain+of+thought"                  exact phrase
au:hinton+AND+cat:cs.LG                combined
```

### Sort and pagination

| Parameter | Values |
|---|---|
| `sortBy` | `relevance`, `lastUpdatedDate`, `submittedDate` |
| `sortOrder` | `ascending`, `descending` |
| `start` | result offset, zero-based |
| `max_results` | number of results, default 10, max 30000 |

`id_list` takes one or more comma-separated identifiers.

### Parsing the Atom feed

The API returns Atom XML, not JSON. Read the URL with the `:raw` suffix so the XML survives, then
parse it with the standard library:

```bash
curl -s "https://export.arxiv.org/api/query?search_query=cat:cs.AI&max_results=5&sortBy=submittedDate&sortOrder=descending" \
| python3 -c "
import sys, xml.etree.ElementTree as ET
ns = {'a': 'http://www.w3.org/2005/Atom'}
root = ET.parse(sys.stdin).getroot()
for i, entry in enumerate(root.findall('a:entry', ns)):
    title = entry.find('a:title', ns).text.strip().replace('\n', ' ')
    arxiv_id = entry.find('a:id', ns).text.strip().split('/abs/')[-1]
    published = entry.find('a:published', ns).text[:10]
    authors = ', '.join(a.find('a:name', ns).text for a in entry.findall('a:author', ns))
    cats = ', '.join(c.get('term') for c in entry.findall('a:category', ns))
    print(f'{i+1}. [{arxiv_id}] {title}')
    print(f'   Authors: {authors}')
    print(f'   Published: {published} | Categories: {cats}')
"
```

### Reading a paper

`read` on a URL returns markdown for both the abstract page and the PDF:

```text
https://arxiv.org/abs/1706.03762     the metadata and the abstract, as markdown
https://arxiv.org/pdf/1706.03762     the full paper, as markdown
https://arxiv.org/html/1706.03762    the HTML rendering, when one exists
```

The **API's** Atom feed is the exception: it is XML, so read it with `:raw`.

### The version suffix

`arxiv.org/abs/1706.03762` always resolves to the **latest** version. `arxiv.org/abs/1706.03762v1`
is immutable. The API's `<id>` field carries the version it actually serves — a query for
`1706.03762` returns `http://arxiv.org/abs/1706.03762v7`, and a query for `1706.03762v1` returns
`...v1`.

**Cite the version you actually read.** A later revision can change the abstract, the experiments,
and the numbers. A citation to the bare identifier points at whichever version is current when the
reader clicks it, which is a different claim from the one the evidence row supports. Record the
versioned identifier in `url_or_path` and the version in `date_or_version`.

### Withdrawn papers

A withdrawn paper keeps its entry, and the `<summary>` field carries the withdrawal notice. Check
the summary before treating a result as a valid paper; a withdrawn result is a fact about the
literature, not evidence for the claim.

## Semantic Scholar graph API

arXiv has no citation data. Semantic Scholar has the citation graph, the references, the
recommendations, and the author profiles. It returns JSON.

```bash
# The paper's metadata and its citation counts.
curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:1706.03762?fields=title,authors,year,citationCount,referenceCount,influentialCitationCount,externalIds,publicationVenue"

# What cites it.
curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:1706.03762/citations?fields=title,authors,year,citationCount&limit=10"

# What it cites.
curl -s "https://api.semanticscholar.org/graph/v1/paper/arXiv:1706.03762/references?fields=title,authors,year,citationCount&limit=20"

# The author.
curl -s "https://api.semanticscholar.org/graph/v1/author/search?query=Yann+LeCun&fields=name,hIndex,citationCount,paperCount"
```

Useful fields: `title`, `authors`, `year`, `abstract`, `citationCount`, `referenceCount`,
`influentialCitationCount`, `isOpenAccess`, `openAccessPdf`, `fieldsOfStudy`, `publicationVenue`,
`externalIds`.

Identifiers: `arXiv:1706.03762`, `DOI:10.1234/example`, or the paper's own Semantic Scholar id.

### The rate limit

**Without an API key, Semantic Scholar returns HTTP 429** — the request is refused before it is
served, so the response body is a rate-limit message and not data. Treat the whole service as
optional: a run that depends on the citation graph will fail, and the arXiv route plus the venue
pages plus the papers' own reference lists cover most of the same ground.

The documented budget is roughly one request per second, and about 100 per second with a key. If
you need it, apply for one and put it in the environment; do not work around the limit by
hammering the endpoint.

## Rate limits at a glance

| Service | Limit | Key |
|---|---|---|
| arXiv API | about one request every three seconds | none needed |
| Semantic Scholar graph API | about one request per second, and **429 without a key** | optional |
| GitHub REST API | 60 requests per hour per IP | optional |

## The paper route in a run

1. **Search** — arXiv by category, title, and author. Log the query as a hop.
2. **Screen** — read the abstracts from the feed. Note the ones that bear on the claim.
3. **Open** — read the abstract page, then the PDF, for the papers that survive screening. Log
   evidence only from papers you opened.
4. **Follow the graph** — the references and the citing papers, through Semantic Scholar when it
   answers and through the papers' own reference lists when it does not.
5. **Look for the counterweight** — the replication that failed, the critique, the survey that
   disagreed, the benchmark that showed contamination. Search for them by name, not by hope.

## Traps

- A search result is a lead. Open the paper before logging an evidence row.
- The abstract is the authors' own summary of their own work. It is not a neutral description, and
  it is not the result table.
- A preprint is unreviewed. Say so in the row.
- Two papers by the same author group are one source family for a claim about that group's work.
- The arXiv identifier without its version suffix drifts; the version suffix does not.
- Semantic Scholar's 429 is not an empty result set. Do not record "no citing papers found" from a
  refused request.
- A citation count measures attention, not correctness, and not replication.
