function httpGetValue(valueName, fieldName)
{
    fetch("getvalue.html?" + valueName)
        .then(response => response.json())
            .then(data => document.querySelector(fieldName).value = data[valueName]);
}

function httpGetContent(contentName, fieldName)
{
    fetch(contentName)
        .then(response => response.json())
            .then(data => document.querySelector(fieldName).value = data);
}

