"""
request(url)

Make a request to the specified URL and return the response body as a string.
If an error occurs, a `RequestError` is thrown.
This function is not intended for direct use. Instead, use the `info`, `list`, and `find`, etc. functions.

# Examples
```julia-repl
request("https://rest.kegg.jp/info/kegg")
```
"""
function request(url::String)
    response = get(url, status_exception = false, verbose = false)

    if (response.status == 200)
        return String(response.body)
    else
        throw(
            RequestError(
                """
                Request to $url failed with status code $(response.status)
                Are you sure your URL called a valid KEGG API endpoint?
                """
            )
        )
    end
end

"""
request_other(url)

Make a request to the specified URL and return the response body as a vector.
If an error occurs, a `RequestError` is thrown.
This function is not intended for direct use.

# Examples
```julia-repl
request_other("https://rest.kegg.jp/image/hsa00010")
```
"""
function request_other(url::String)
    response = get(url, status_exception = false, verbose = false)

    if (response.status == 200)
        return response.body
    else
        throw(
            RequestError(
                """
                Request to $url failed with status code $(response.status)
                Are you sure your URL called a valid KEGG API endpoint?
                """
            )
        )
    end
end
