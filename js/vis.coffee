
serverURL = "http://localhost:8080/DiTopWeb/DiTopServlet"

configurations = {}
selectedSet = 0
selectedTopicSize = 0
cloudData = []
svg = d3.select("#vis").append("svg").attr("width",1000).attr("height",800)
slotsHorizontal = 6
slotSize = 150

fill = d3.scale.category10();


$("#showButton").click( ->
  key = Object.keys(configurations)[selectedSet]
  topicSize = configurations[key][selectedTopicSize]
  loadDataSet(key+"_"+topicSize)
)
$("#sortButton").click(-> sortAndUpdate())

$.ajax
  url: serverURL,
#  data: "q="+encodeURIComponent(inputData.toLowerCase())+"&rows=0&facet=true&facet.query=p1:1&facet.query=p2:1&facet.query=p3:1&facet.query=p4:1&facet.query=p5:1&facet.query=p6:1&facet.query=p7:1&facet.query=p8:1&facet.query=p9:1&facet.query=p10:1&facet.query=p11:1&facet.query=p12:1&facet.query=p13:1&facet.query=p14:1&facet.query=p15:1&facet.query=p16:1&facet.field=text&facet.field=sp&facet.field=ngram&facet.sort=count&wt=json",
  dataType: 'jsonp',
  jsonp: 'callback',
  success: (resData) ->
    if resData?
      configurations = resData
      updateDataSet()

    console.log resData


updateDataSet = ->
  keys = Object.keys(configurations);
  dList = d3.select("#datasetList")
  dList.clear
  elementList= dList.selectAll("a").data(keys)
  elementList.enter().append("a")
  .classed("list-group-item",true)
  .classed("active",(d,i) -> i==selectedSet)
  .on("click", (d,i) ->
      selectedSet = i
      selectedTopicSize =0
      updateDataSet()
    )
  .text((d,i) -> d )
  elementList.classed("active",(d,i) -> i==selectedSet)

  topicSizes = configurations[keys[selectedSet]]
  sList = d3.select("#topicSizesList")
  elementList = sList.selectAll("a").data(topicSizes)
  elementList.enter().append("a")
  .classed("list-group-item",true)
  .classed("active",(d,i) -> i==selectedTopicSize)
  .on("click", (d,i) ->
        selectedTopicSize = i
        updateDataSet()
    )
  .text((d,i) -> d )
  elementList.classed("active",(d,i) -> i==selectedTopicSize)

loadDataSet = (datasetName)->
  console.log(datasetName)
#http://localhost:8080/DiTopWeb/DiTopServlet?dataset=New3000_40
  $.ajax
    url: serverURL,
    data: "dataset="+datasetName,
    dataType: 'jsonp',
    jsonp: 'callback',
    success: (resData) ->
      if resData?
        cloudData = []
        for k,v of resData
          cloudData.push(v)

        console.log(cloudData)
        drawClouds()

sortAndUpdate = ->
  cloudData.sort((a,b) ->
    a.inSetBitvector - b.inSetBitvector
  )
  cdGroups = svg.selectAll(".clouds").data(cloudData, (d) -> d.groupName)

  #transform="translate(300,300) rotate(-60)"
  cdGroups.transition().duration(1000)
   .attr("transform",(d,i) -> "translate("+(i%slotsHorizontal*slotSize+ 50)+"," + ((i/slotsHorizontal >>0) *slotSize+50)+")")

  set1Items = getBitIndices(1,cloudData)
  set2Items = getBitIndices(2,cloudData)
  set4Items = getBitIndices(4,cloudData)
  console.log set1Items
  console.log set2Items

  addGroupItems(set1Items,"set1Items",-13)
  addGroupItems(set2Items,"set2Items",0)
  addGroupItems(set4Items,"set4Items",+13)





drawClouds = ->
  cdGroups = svg.selectAll(".clouds").data(cloudData, (d) -> d.groupName)

  #transform="translate(300,300) rotate(-60)"
  d3.transition(cdGroups)
    .attr("transform",(d,i) -> "translate("+(i%slotsHorizontal*slotSize+ 50)+"," + ((i/slotsHorizontal >>0) *slotSize+50)+")")
  cdGroups.exit().remove()
  clouds = cdGroups.enter().append("g").classed("clouds",true)
  clouds
    .attr("transform",(d,i) -> "translate("+(i%slotsHorizontal*slotSize+ 50)+"," + ((i/slotsHorizontal >>0) *slotSize+50)+")")
  clouds.selectAll("text").data((d) -> d.terms).enter().append("text")
    .attr("x", (d) ->d.xPos)
    .attr("y", (d) ->d.yPos)
    .attr("text-anchor","middle")
    .style("font-size", (d) -> (d.size-1.5))
    .text((d) -> d.text)
  for x in [-1..1]
    clouds.append("rect").classed("emptyRect",true)
      .attr
        x: x*13
        y: 50
        width: 10
        height: 10

  set1Items = getBitIndices(1,cloudData)
  set2Items = getBitIndices(2,cloudData)
  set4Items = getBitIndices(4,cloudData)
#
  addGroupItems(set1Items,"set1Items",-13, true)
  addGroupItems(set2Items,"set2Items",0,true)
  addGroupItems(set4Items,"set4Items",+13,true)


getBitIndices = (bitmask, cData) ->
  res = []
  for d,i in cData
    res.push(i) if (d.inSetBitvector & bitmask)
  res

addGroupItems = (setItems, className, offsetX, clearAll = false) ->


  setVisItems = svg.select("."+className)
  if setVisItems.empty()
    setVisItems = svg.append("g").classed(className, true)
  else if clearAll
    setVisItems.selectAll(".setItem").remove()
    setVisItems.selectAll(".bgR").remove()


  allItems = setVisItems.selectAll(".setItem").data(setItems, (d) -> d)
  allItems.exit().remove()
  allItems.transition()
    .style
      opacity:0
    .transition().duration(2)
      .attr
        x: (d) -> d%slotsHorizontal*slotSize + 50+offsetX
        y: (d) -> ((d/slotsHorizontal >>0) *slotSize+100)
    .transition().duration(500)
      .style
        opacity:1

  allItems.enter().append("rect").classed("setItem",true)
    .attr
      x: (d) -> d%slotsHorizontal*slotSize + 50+offsetX
      y: (d) -> ((d/slotsHorizontal >>0) *slotSize+100)
      width: 10
      height: 10
    .style
      'fill': fill(className)
    .on
      'mouseover':  ->
        d3.selectAll("."+className+" .bgR")
        .style
          'stroke':fill(className)
          'opacity': 0.0
        .transition().duration(500)
        .style
          'opacity': .9
      'mouseout':->
        d3.selectAll("."+className+" .bgR").transition().duration(500)
        .style
          'opacity': 0


  bgRs = setVisItems.selectAll(".bgR").data(setItems, (d) -> d)
  bgRs.exit().remove()
  bgRs.enter().append("rect").classed("bgR",true)
    .attr
      x: (d) -> d%slotsHorizontal*slotSize+2
      y: (d) -> ((d/slotsHorizontal >>0) *slotSize)+2
      width: 96
      height: 96
    .style
      'fill': 'none'
      'stroke-width': 3
      'opcacity': 0
