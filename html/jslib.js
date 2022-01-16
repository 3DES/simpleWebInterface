"use strict";

const dataRequest = "data-requests";
const dataUpload  = "data-upload";
const getValueUrl = "getvalue.html";
const setValueUrl = "setvalue.html";


async function httpGetValue(valueName)
{
    let response = await fetch(getValueUrl + "?" + valueName);

    let data     = await response.json();
    let fieldName = '#' + valueName;

    let object = document.querySelector(fieldName);
    if ((object.localName == "input") && (object.type == "checkbox")) {
        // slider
        object.checked = (data[valueName] ? true : false);
    }
    else if (object.localName == "input") {
        // text field
        object.value = data[valueName];
    }
    else if (object.localName == "select") {
        // list box
        while (object.firstChild) {
            object.removeChild(object.lastChild);
        }
        let list = data[valueName];
        let selected = list.shift();
        list.forEach(listEntry => {
            let option = document.createElement("option");
            option.value = listEntry;
            option.appendChild(document.createTextNode(listEntry));
            object.appendChild(option);
        });
        if (selected >= 0 && selected < list.length) {
            object.options[selected].selected = "selected";
        }
        //object.options[selected].style.color = "green";
    }
    else {
        // anything else (hopefully works)
        object.innerText = data[valueName];
    }
}

//function httpGetContent(contentName, fieldName)
//{
//    fetch(contentName)
//        .then(response => response.text())
//            .then(data => {
//                document.querySelector(fieldName).innerHTML = data;
//            });
//}

function upload(element) {
    if (element.hasAttribute(dataUpload)) {
        var data = JSON.parse(element.getAttribute(dataUpload));
        let uploads = Object.keys(data);
        uploads.forEach(upload => {
            let content;
            let type = data[upload];
            let input = document.getElementById(upload);
            
            switch (type) {
                case "edit":
                case "date":
                case "time":
                    content = input.value;
                    break;
                case "list":
                    content = input.options[input.selectedIndex].value;
                    break;
                case "slider":
                    content = input.checked ? "1" : "0";
                    break;
                case "hostname":
                case "ip4":
                case "mac":
                    if (input.checkValidity()) {
                        content = input.value;
                    }
                    else {
                        window.alert("input of [" + upload + "] is not valid!");
                    }
                    break;
                default:
                    window.alert("unhandled type [" + type + "] in upload()");
                    break;
            }
            
            if (content.length) {
                fetch(setValueUrl, {
                    method: 'post',
                    headers: {'Content-Type' : 'application/json'},
                    body: "{ \"" + upload + "\" : \"" + content + "\" }"
                });
            }
        });
    }
}


function hasFlag(element, flag) {
    var result = false;
    if (element.flags != null) {
        if (flag == "length") {
            var regex = /^length *= *(\d+)$/;
            var index = 0;
            var matched;
            for (; index < element.flags.length && (matched = element.flags[index].match(regex)); index++);
            if (matched != null && matched[1] > 0) {
                result = matched[1];
            }
        }
        else {
            result = element.flags.includes(flag);
        }
    }

    return result;
}


function createBlock(block, columns = 2, titleWidth = "60%") {
    let requestCollect = [];
    let refreshCollect = [];
    let uploadCollect  = {};

    let blockName = block.name;
    let columnWidth = (block.width != null) ? block.width : "50%";

    let html = "<td width=\"" + Math.floor(100 / columns - 2) + "%\" style=\"vertical-align:top\">\n";
    html += "<div class=\"block\">\n";
    html += "<div class=\"blockheader\">\n";
    html += "<div class=\"blocktitle\" style=\"width:" + titleWidth + "\">" + blockName + "</div>\n";
    html += "</div>\n";
    html += "<div class=\"blockline\"></div>\n";
    html += "<div class=\"blockcontent\">\n";
    html += "<table width=\"100%\">\n";

    // handle all block entries
    block.elements.forEach(element => {
        let elementName = element.name;
        let requestName = element.tag;
        html += "<tr><td width=\"" + columnWidth + "\">" + elementName + "</td><td>\n";
        let type = (element.type != null) ? element.type : "text";
        var readonly = false;
        var textDefault = "<input type=\"text\" style=\"width:90%\" ";
        switch(type) {
            default:
                readonly = true;
                window.alert("unhandled type [" + type + "] in createBlock()");
                break;
            case "text":
                // such elements are always readonly
                readonly = true;
                html += "<div id=\"" + requestName + "\"></div>\n";
                break;
            case "edit":
                readonly = hasFlag(element, "readonly");
                var setLength = hasFlag(element, "length");
                html += textDefault + "id=\"" + requestName + "\" " + (readonly ? "readonly" : "") + (setLength ? " maxlength=" + setLength : "") + ">\n";
                break;
            case "date":
                readonly = hasFlag(element, "readonly");
                html += "<input type=\"date\" id=\"" + requestName + "\" " + (readonly ? "readonly" : "") + ">\n";
                break;
            case "time":
                readonly = hasFlag(element, "readonly");
                //html += "<input type=\"time\" id=\"" + requestName + "\" " + (readonly ? "readonly" : "") + ">\n";
                html += "<input type=\"time\" step=\"60\" id=\"" + requestName + "\" " + (readonly ? "readonly" : "") + ">\n";
                break;
            case "ip4":
                html += textDefault + "id=\"" + requestName + "\" " + "maxlength=\"15\" pattern=\"^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)(\\.(?!$)|$)){4}$\">\n";
                break;
            case "hostname":
                html += textDefault + "id=\"" + requestName + "\" " + "maxlength=\"30\" pattern=\"^[A-Za-z]([A-Za-z0-9\\-]{0,28}[A-Za-z0-9])?$\">\n";
                break;
            case "mac":
                html += textDefault + "id=\"" + requestName + "\" " + "maxlength=\"17\" pattern=\"^([0-9A-F]{2}:){5}[0-9A-F]{2}$\">\n";
                break;
            case "list":
                readonly = hasFlag(element, "readonly");
                html += "<select id=\"" + requestName + "\" " + (readonly ? "disabled=\"true\"" : "") + ">\n";
                break;
            case "slider":
                readonly = hasFlag(element, "readonly");
                html += "<label class=\"switch\">\n";
                html += "<input type=\"checkbox\" id=\"" + requestName + "\" " + (readonly ? "onclick=\"return false;\"" : "") + ">\n";
                html += "<span class=\"slider round\"></span>\n";
                html += "</label>\n";
                break;
        }
        html += "</td></tr>\n";

        if (!readonly) {
            uploadCollect[ requestName ] = type;
        }

        requestCollect.push(requestName);
        if (hasFlag(element, "refresh")) {
            refreshCollect.push(requestName);
        }
    });

    html += "</table>\n";
    html += "</div>\n";
    html += "</div>\n";
    html += "</td>\n";

    return [html, requestCollect, refreshCollect, uploadCollect];
}


/**
 * Creates a page structure from given json blocks
 *
 * @param activeFunction        function that has to return true in case divObject is active (and therefore a refresh of all refresh parameters have to be done)
 * @param divObject             object that has innerHTML to be filled (e.g. div)
 * @param blocks                json structure containing blocks to create page structure
 * @param columns               amount of columns, default is 2
 * @param titleWidth            width of the colored title part
 * @param refreshInterval       time in ms refresh elements have to be reloaded (default is 5000ms)
 *
 * [{"name":"<blockName>","width":"<width>", "elements":[["name":"<elementName>","tag":"<elementTag>","type":"<elementType>","flags":"[<elementFlag>,<elementFlag>,...]"]]
 *
 * blockName   [mandatory]  will be used as header text
 * width       [optional]   with of the column containing element names (default is 50%)
 * elementName [mandatory]  will be used in line "<elementName><elementValue>"
 * elementTag  [mandatory]  will be used as tag to request <elementValue> from server
 * elementType [optional]   type of given element, default is "text" if not given
 *                          supported types:
 *                              text        pure text, always readonly!
 *                              slider      check box slider
 *                              edit        text field, usually editable
 *                              date        date field
 *                              time        time field
 *                              ip4         ip4 field (invalid entry will be shown in red)
 *                              mac         mac field (invalid entry will be shown in red)
 *                              host        hostname field (invalid entry will be shown in red)
 *                              list        list
 *                              user        user defined field (whole entry will just be inserted)
 * elementFlag [optional]   type of given element
 *                          supported types:
 *                              readonly        usually editable elements can be disabled, e.g. just to show a state but don't let the user change it
 *                              refresh         element will automatically be refreshed with "default" refresh time
 *                              length = xxx    maximum length of element
 *
 *      supported type/flag combinations
 *             | readonly | refresh | length |
 *      -------|----------|---------|--------|-------------------
 *      text   | default  |    X    |   X    |
 *      slider |    X     |    X    |        |
 *      edit   |          |    X    |   X    |
 *      date   |    X     |    X    |        |
 *      time   |    X     |    X    |        |
 *      ip4    | use text |    X    |        |
 *      mac    | use text |    X    |        |
 *      host   | use text |    X    |        |
 *      list   |          |    X    |        |
 *      user   |          |    X    |        |
 *
 */
function processBlocks(activeFunction, divObject, blocks, columns = 2, titleWidth = "60%", refreshInterval = 5000) {
    function refresh(activeFunction, refreshes) {
        if (activeFunction()) {
            refreshes.forEach(refresh => {
                httpGetValue(refresh);
            });
        }
    }

    let refreshes = [];

    if (divObject.hasAttribute(dataRequest)) {
        // refresh function will be called periodically to refresh all elements with flag "refresh"
        refreshes = divObject.getAttribute(dataRequest).split(",");
        refresh(activeFunction, refreshes);
    }
    else {
        var innerHtml = "";
        var blockCount = 0;

        let requests = [];
        let uploads  = {};
        innerHtml += "<table width=\"100%\"\n";
        blocks.forEach(block => {
            if (!(blockCount % columns)) {
                innerHtml += "<tr>\n";
            }

            if (blockCount % columns) {
                innerHtml += "<td></td>\n";
            }

            if (block.name != null) {
                let htmlAndRequests = createBlock(block, columns, titleWidth);
                innerHtml += htmlAndRequests[0];
                requests   = requests.concat(htmlAndRequests[1]);
                refreshes  = refreshes.concat(htmlAndRequests[2]);
                uploads    = { ...uploads, ...htmlAndRequests[3]};
            }
            else {
                // create empty block
                innerHtml += "<tr><td></td></tr>\n";
            }

            if (blockCount % columns == (columns - 1)) {
                innerHtml += "</tr>\n";
                innerHtml += "<tr>\n";
                innerHtml += "<td height=\"20px\">\n";
                innerHtml += "</td>\n";
                innerHtml += "</tr>\n";
            }

            blockCount++;
        });

        if (Object.values(uploads).length > 0) {
            innerHtml += "<tr><td><div><button onclick=\"upload(" + divObject.id + ")\">SAVE</button>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<button onclick=\"repaint()\">CANCEL</button></div></td></tr>";
        }

        innerHtml += "</table>\n";

        // conent has been created so fill it to parent
        divObject.innerHTML = innerHtml;
        //document.getElementById("overviewContent").innerHTML = innerHtml;

        // request all elements from server
        requests.forEach(request => {
            httpGetValue(request);
        });

        // refresh function will be called periodically to refresh all elements with flag "refresh"
        function refresh(activeFunction, refreshes) {
            if (activeFunction()) {
                refreshes.forEach(refresh => {
                    httpGetValue(refresh);
                });
            }
        }

        // refresh all elements with "refesh" flag every given refreshInterval ms
        if (refreshes.length > 0) {
            setInterval(function() {
                refresh(activeFunction, refreshes);     // this indirect function is necessary since otherwise refreshes doesn't exist anymore when refresh() is executed!
            }, refreshInterval);
        }

        divObject.setAttribute(dataRequest, requests);
        divObject.setAttribute(dataUpload, JSON.stringify(uploads));
    }
}

var cssIds = [ 'slider.css', 'blocks.css' ];
cssIds.forEach(css => {
    if (!document.getElementById(css))
    {
        var head  = document.getElementsByTagName('head')[0];
        var link  = document.createElement('link');
        link.id   = css;
        link.rel  = 'stylesheet';
        link.type = 'text/css';
        link.href = css;
        link.media = 'all';
        head.appendChild(link);
    }
});
