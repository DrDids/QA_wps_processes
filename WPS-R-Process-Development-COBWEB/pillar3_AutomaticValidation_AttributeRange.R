#################################################################
# COBWEB QAQC February 2016
# pillar3 AutomaticValidation
# some typical QCs
#
# Didier Leibovici Julian Rosser and Mike Jackson University of Nottingham
#
# each function is to be encapsulated as process part of the WPS
# input format and output format of the data and metadata 
# are managed within the java wrapper 


# pillar3.AutomaticValidation.xxxx 
#   where xxxx is the name of the particular QC test


#  pillar3.AutomaticValidation.AttributeRange
#     to compare an attribute value with an expert given range with the aim of validating normal or abnormal expected values
#     with possible feedback for correction
##################################################################
#describtion set for WPS4R
# input  set for 52North WPS4R
#output set for 52North WPS4R

# wps.des: pillar3.AutomaticValidation.AttributeRange , title = pillar3 AutomaticValidation AttributeRange, abstract = QC test comparing quantitative attribute input Obs to given expert range of values; 

# wps.in: inputObservations, application/x-zipped-shp;

# wps.in: ObsAttribFieldName, string, title = AttributeName,  abstract = attribute name existing in the vector format; 
# wps.in: UUIDFieldName, string, title = the ID fieldname,  abstract = attribute name existing in the inputObservations; 

# wps.in: QualQuant, string, title= qual or quant, abstract= qualitative or quantitative; 

# wps.in: RangeOfAttribute, string, title = two values of min and max, abstract= values given as in R style; 
# wps.in: UsabScore, double, title= 0 to 1 score, abstract= Subjective value given to direct usability of being in the range ie if the range is large because of lack of expertise knowledge its direct usability is low; 

# wps.in: ObsMeta, string, value= NULL,title = Observation metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s) ; 
# wps.in: VolMeta, string, value= NULL,title = Volunteer metadata, abstract= can be NULL in an xml file or as inputObservations. If given will update the metadata record(s); 

################################################################
#libraries to read gml  or shapefile or geoJSON or ....
# see possible file formats  ogrDrivers()   ...
#####################ISO10157#############
DQ=c("DQ_UsabilityElement","DQ_CompletenessCommission","DQ_CompletenessOmission","DQ_ThematicClassificationCorrectness",
"DQ_NonQuantitativeAttributeCorrectness","DQ_QuantitativeAttributeAccuracy","DQ_ConceptualConsistency","DQ_DomainConsistency","DQ_FormatConsistency","DQ_TopologicalConsistency","DQ_AccuracyOfATimeMeasurement","DQ_TemporalConsistency","DQ_TemporalValidity","DQ_AbsoluteExternalPositionalAccuracy","DQ_GriddedDataPositionalAccuracy","DQ_RelativeInternalPositionalAccuracy")
####################GeoViQUA basic########
GVQ=c("GVQ_PositiveFeedback","GVQ_NegativeFeedback") #can be used also for user
################# Stakeholder Quality Model 
CSQ=c("CSQ_Ambiguity","CSQ_Vagueness","CSQ_Judgement","CSQ_Reliability","CSQ_Validity","CSQ_Trust","CSQ_NbControls")
###########################################
DQlookup=cbind(c(paste("DQ_0",1:9,sep=""),paste("DQ_",10:16,sep=""),paste("GVQ_0",1:2,sep=""),paste("CSQ_0",1:7,sep="")), c(DQ,GVQ,CSQ)) 
###########################################
colnames(DQlookup)=c("code","name")
###########################################
 DQ_Default=c(0.5,0.5,0.5,0.5,0.5,NA,0.5, 0.5, 0.5, 0.5,NA, 0.5, 0.5,888,888,888, 0, 0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,0)
DQ_MeasureUnit=c("%","%","%","%","%","variance","%","%","%","%","CE68ie1sd","%","%","meters","meters","meters","count","count","%","%","%","%","%","%","count") 
## rather otimistic by default but with pessimistism 
 # for DQ_04 and DQ_11 measure will be variance and if NA will be the value (>0) as a Poisson
 # but position uncertainty
 DQlookup=cbind(DQlookup,DQ_MeasureUnit, DQ_Default)
################################################### function used   
pillar3.AttributeRange <-function(ObsAttrib){
	# all this is at feature level
	#expert range
	# 	
	VolMetaQ[i,"CSQ_07"]<<-VolMetaQ[i,"CSQ_07"]+1
	if(QualQuant=="Quant")inRange=(RangeOfAttribute[1] <= ObsAttrib & ObsAttrib <= RangeOfAttribute[2])
	if(QualQuant=="Qual")inRange=(grepl(RangeOfAttribute[1],ObsAttrib) | grepl(RangeOfAttribute[2],ObsAttrib) )
	if(inRange) {	
		if(ObsMetaQ[i,"DQ_01"]!=0.5)ObsMetaQ[i,"DQ_01"]<<-mean(c(ObsMetaQ[i,"DQ_01"], UsabScore)) else ObsMetaQ[i,"DQ_01"]<<-UsabScore ## attempt to see if if it was the first time i.e. default value 0.5
		VolMetaQ[i,"CSQ_03"]<<-min(c(VolMetaQ[i,"CSQ_03"] + UsabScore/10, 1)) #judgement
		VolMetaQ[i,"CSQ_04"]<<-mean(c(VolMetaQ[i,"CSQ_03"], UsabScore,VolMetaQ[i,"CSQ_04"])) # reliability
		trustHere= min(c((VolMetaQ[i,"CSQ_05"]+VolMetaQ[i,"CSQ_03"]*VolMetaQ[i,"CSQ_04"]/2)/UsabScore, 1)) # (valid+reli*judg)/(2*UsabScore)
		VolMetaQ[i,"CSQ_06"]<<-(VolMetaQ[i,"CSQ_06"] + trustHere)/2  # updated trust
		VolMetaQ[i,"CSQ_06"]<<-min(c(1,VolMetaQ[i,"CSQ_06"] + (1-VolMetaQ[i,"CSQ_06"])/10)) # special bonus 
	}
	else{
		ObsMetaQ[i,"DQ_01"]<<-mean(c(ObsMetaQ[i,"DQ_01"],max(c(0,ObsMetaQ[i,"DQ_01"]-UsabScore/5)) ) )#DQ_Usability
		VolMetaQ[i,"CSQ_04"]<<-mean(c(VolMetaQ[i,"CSQ_04"],VolMetaQ[i,"CSQ_3"])) # reliability

	
	}
	
		
}# AttributRange

### 

getdsn<-function(tt){
	fin=substr(tt,nchar(tt)-3,nchar(tt))
	if(fin==".gml")return(tt)
	dd=strsplit(tt,"/")[[1]]
	if(length(dd)==1)return(".")
	else return(sub(dd[length(dd)],"",tt,fixed=TRUE))
}#end of dsn

measureSelectPath <-function(DQ_element,meas="geographic"){
 	#encoding= c("boolean" ,"character", "numeric")
 	# example path [.//gmd:measureDescription/gco:CharacterString/text()='geographic'] see expr in GetSetMetaQ
 	encoding="numeric"
 	path=""
 	 if(DQ_element=="DQ_RelativeInternalPositionalAccuracy,")path=paste0("[.//gmd:measureDescription/gco:CharacterString/text()=","\'",meas,"\'","]")
 	 if(DQ_element=="DQ_ConceptualConsistency")encoding="boolean"
 	 
 return(list("path"=path,"encoding"=encoding))
 }
 
GetSetMetaQ<-function(Meta,listQ=c(1,3), Idrecords=NULL,scope=NULL){
	# "CSW","SOS","WFS",scope=c("observation","dataset","user")
	# QQ list the fields more than columns for potential different naming
	# get if they exists corresponding fields DQ GVQ or CSQ
	# 
	#
	#listQ are %in% 1:25 nb of rows of DQlookup
	# are encode using DQlookup[,1]
	# 
	
	defaultMeta <-function(Meta){
  		# with
  		# DQ_Default=c(0.5,0.5,0.5,0.5,0.5,NA,0.5, 0.5, 0.5, 0.5,NA, 0.5, 0.5,888,888,888, 0, 
  		#0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,0)
        # DQ_MeasureUnit=c("%","%","%","%","%","variance","%","%","%","%","CE68ie1sd","
        #      %","%","meters","meters","meters","count","count","%","%","%","%","%","%","count") 
         
 		 if("DQ_16" %in% colnames(Meta) && "DQ_14" %in% colnames(Meta)){
  			Meta[is.na(Meta[,"DQ_16"]),"DQ_16"]=Meta[is.na(Meta[,"DQ_16"]),"DQ_14"]
  		}
  		for (co in colnames(Meta)){
  		Meta[is.na(Meta[,co]),co]=as.numeric(DQlookup[DQlookup[,1]==co, "DQ_Default"])
  		}
  	return(Meta)
  	}#end of defaultMeta
  
	dim2=length(listQ)
	
	if(is.null(Idrecords)) dim1=1 else dim1=length(Idrecords)
	MetaQ=matrix(rep(NA,dim1*dim2),c(dim1,dim2))
		MetaQ=as.data.frame(MetaQ)
		colnames(MetaQ)= DQlookup[listQ,1] # 1 is DQ_01 etc 2 is DQ_UsabilityElement etc ..
		if(!is.null(Idrecords)) rownames(MetaQ)=Idrecords
	
	MetaQ=defaultMeta(MetaQ)
	if(is.null(Meta) || Meta=="NULL"|| Meta=="") return(MetaQ)
		
	if(is.object(Meta) ){ # Meta already read by readOGR simple gml or shp
		if(class(Meta)[1] %in% c("SpatialPointsDataFrame","SpatialPolygonsDataFrame","SpatialLinesDataFrame","SpatialGridDataFrame"))Meta=Meta@data
		for (j in listQ){
			if (DQlookup[j,1] %in% colnames(Meta)) MetaQ[,DQlookup[j,1]]=Meta[,DQlookup[j,1]]
			else if (DQlookup[j,2] %in% colnames(Meta)) MetaQ[,DQlookup[j,1]]=Meta[,DQlookup[j,2]]
			#else Meta@data<<-cbind(Meta@data,MetaQ[,DQlookup[j,1]]) # add columns in with NA
		}
	}
	else {
		library(XML); #library(XML2R) # XML2R needs an url
		## putting  DQ_ elements (CSQ or GVQ)	
			 Meta.all <- xmlParse(Meta, isURL=TRUE) #, isURL= isUrl(Meta))
			for (j in listQ){ 
				q=DQlookup[j,2];q1=DQlookup[j,1]
				scopeSelect=""
				if(!is.null(scope))scopeSelect=paste0("[.//gmd:MD_ScopeCode[@codeListValue=","\'", scope ,"\'","] ]") #scope='dataset' scope='feature
				measureSelect=measureSelectPath(q)
				expr=paste0("//gmd:DQ_DataQuality", scopeSelect,"//gmd:",q,measureSelect$path, "//gco:Record")
				node=getNodeSet(Meta.all,expr) # to get DQ_element "value" ....
				#"//gmd:DQ_DataQuality[.//gmd:MD_ScopeCode[@codeListValue='dataset'] ]//gmd:DQ_RelativeInternalPositionalAccuracy[.//gmd:measureDescription/gco:CharacterString/text()='geographic']//gco:Record"
				# would have been better to get a first node and look for gco:Record and gf:Id afterwards but getNodeSet  ... can be done by  XMLDoc  of a node[[i]]
# or now we supose that UUID is an attribute of <gco:Record UUID='lepreumz">
				nolen=length(node)
				if(nolen>=1){
					for (i in 1:nolen){
						iI=i
						if(scope=="feature" && !is.null(node[[i]])){
							if(!is.null(Idrecords))iI=xmlGetAttr(node[[i]],"gml:id")
						}
			    		if(measureSelect$encoding=="numeric")MetaQ[iI,q1]=as.numeric(xmlValue(node[[i]]))
			    		else if(measureSelect$encoding=="boolean")MetaQ[iI,q1]=as.factor(xmlValue(node[[i]]))
			    		else MetaQ[iI,q1]=xmlValue(node[[i]])
					}
				}
			}	
	}
	MetaQ=defaultMeta(MetaQ)
return(MetaQ)
}#end of GetSetMetaQ as a matrix

cbindUP <-function(dat, datU){
	# remove from dat the columns list DQ
	# could do with a ... there 
	for (c in colnames(datU)){
		if (c %in% colnames(dat))dat[,c]=datU[,c]
		else {
		temp=colnames(dat)
		dat=cbind(dat,datU[,c])
		colnames(dat)=c(temp,c)
		}
	}
return(dat)
}#cbindUP

################################################################
#libraries to read gml  or shapefile or geoJSON or ....
# see possible file formats  ogrDrivers()   ...

testInit<-function(){
  #setwd("C:\\Users\\ezzjfr\\Documents\\R_scripts\\JKWData4Pillar5_proxmitySuitabilityPOlygonScore\\JKWData\\")
  #inputObservations<<- "SnowdoniaNationalParkJapaneseKnotweedSurvey_AllPoints_EnglishCleaned_final.shp"
  setwd("C:\\Users\\ezzjfr\\Documents\\R_scripts\\JKWData4Pillar5_proxmitySuitabilityPOlygonScore\\")
  inputObservations<<- "SnowdoniaNationalParkJapaneseKnotweedSurvey.shp"
  
  #setwd("/Users/lgzdl/Documents/Dids/DidsE/COBWEB/Co-Design/JKW knotweed (Snodonian)/DidData/")	
  #inputObservations<<-"SnowdoniaNationalParkJapaneseKnotweedSurvey_AllPoints_EnglishCleaned_final.shp"   
  
  ObsAttribFieldName<<-"Roll"
  RangeOfAttribute<<-"c(-1_ 5)"
  QualQuant<<-"Quant"
  UsabScore <<-0.7
  UUIDFieldName<<-"Iden"     #string
  #UUIDFieldName<<-"timestamp"  
  VolMeta <<-inputObservations
  ObsMeta<<-inputObservations
  FilterOut<<-"FALSE"
} # to be commented when in the WPS


# wps.off
#testInit()
# wps.on


######
library(XML)
library(rgdal)
library(rgeos)
library(maptools)
library(sp)
library(rgdal)


RangeOfAttribute=eval(parse(text= gsub("_",",", RangeOfAttribute)))


#julian readOGR of observations
layername <- sub(".shp","", inputObservations) # just use the file name as the layer name
Obsdsn = inputObservations
#Obs <- readOGR(dsn = Obsdsn, layer = layername) # Broken for multi-point reading
readMultiPointAsOGR = function(filename) {  
  library(maptools)
  shape <- readShapePoints(filename)
  tempfilename = paste0(filename,"_tempfilenametemp")
  writeOGR(shape, ".", tempfilename, driver="ESRI Shapefile")
  #ogrInfo(".",tempfilename )
  tempObs <-readOGR(".",layer= tempfilename) # 
  return(tempObs)
}
Obs = readMultiPointAsOGR(layername )



#Didier read OGR
#Obsdsn= inputObservations #getdsn(inputObservations) #"." 
#inputObservations=ogrListLayers(Obsdsn)[1] # supposed only one layer
#GML=attr(ogrListLayers(Obsdsn),"driver")=="GML"
#Obs <-readOGR(Obsdsn,layer= inputObservations)


# metaQ as matrices
# metaQ as matrices/vector
ObsMetaQ=ObsMeta
VolMetaQ=VolMeta # "string names"
#then 
# metaQ as matrices/vector

if(!is.null(ObsMeta) && ObsMeta == Obsdsn)ObsMetaQ=Obs@data # shp or gml idem otherwise will be xml from a CSW
if(!is.null(VolMeta) && VolMeta == Obsdsn)VolMetaQ=Obs@data

ObsMetaQ=Obs@data # shp or gml idem otherwise will be xml from a CSW
VolMetaQ=Obs@data

#obs c(1)Auth c() vol c(21:25)
ObsMetaQ=GetSetMetaQ(ObsMetaQ,listQ=c(1),Idrecords= Obs@data[,UUIDFieldName])

VolMetaQ=GetSetMetaQ(VolMetaQ,listQ=c(21:25), Idrecords =Obs@data[,UUIDFieldName],scope='volunteer')

############################
# Main loop for each citizen

for (i in 1:dim(Obs@data)[1]){
	 
		Res=pillar3.AttributeRange(Obs@data[i, ObsAttribFieldName])

}

#
####### metadata of data quality ouput
##	

outputForma="allinWFS" #  observations were in a WFS and we add on DQs ...!!!
		               #"CSW" or "SOS" a ISO19157 reporting is made and either 
		               #sent to a CSW or with the observations in O&M
fullQualityNames=FALSE

## all in WFS
if(outputForma=="allinWFS"){
	if(fullQualityNames){ # for the full names
		colnames(ObsMetaQ)=DQlookup[DQlookup[,1]==colnames(ObsMetaQ),2]
		colnames(VolMetaQ)=DQlookup[DQlookup[,1]==colnames(VolMetaQ),2]
		}
	Obs@data=cbindUP(cbindUP(Obs@data,ObsMetaQ), VolMetaQ)
	
}

#
# as metadata xml write 
if(outputForma=="CSW"||outputForma=="SOS" ){
	# to create an ISO19157 XML to be potentially integrated in an ISO19115/19139 encoding
	#
}


#out processing
UpdatedObs=paste0(layername, "_outP3AR.shp")
writeOGR(Obs,UpdatedObs,"data","ESRI Shapefile")
# wps.out: UpdatedObs, shp_x, returned geometry;

# old out ObsMetaQ.output, xml, title = Observation metadata for quality updated, abstract= each feature in the collection; 
# old out AuthMetaQ.output, xml, title = Auth metadata updated if asked for, abstract= each feature in the collection; 
# old out UserMetaQ.ouput, xml, title = User metadata for quality updated, abstract= each feature in the collection; 

# outputs  by WPS4R
