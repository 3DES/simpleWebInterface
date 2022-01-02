function httpGetValue(valueName, fieldName)
{
    fetch("http://localhost:8080/getvalue.html?" + valueName)
        .then(response => response.json())
            .then(data => document.querySelector(fieldName).value = data[valueName]);
}
