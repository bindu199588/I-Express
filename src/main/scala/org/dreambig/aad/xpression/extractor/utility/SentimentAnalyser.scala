
package org.dreambig.aad.xpression.extractor.utility

import java.util.Properties

import com.databricks.spark.corenlp.functions._
import edu.stanford.nlp.ling.CoreAnnotations
import edu.stanford.nlp.neural.rnn.RNNCoreAnnotations
import edu.stanford.nlp.pipeline.StanfordCoreNLP
import edu.stanford.nlp.sentiment.SentimentCoreAnnotations
import org.apache.spark.rdd.RDD
import org.apache.spark.sql.SQLContext
import org.apache.spark.sql.functions._
import org.dreambig.aad.xpression.bean.{SentimentIdx, TagMessage}
import org.dreambig.aad.xpression.extractor.utility.logging.InHouseLogging


/**
  * Created by npatodi030716 on 3/2/2017.
  */
object SentimentAnalyser extends InHouseLogging{

  private val SentimentMap = Map(0 -> "upset", 1 -> "sad", 2 -> "neutral", 3 -> "happy", 4 -> "glad")
  private val emoticonsMap= Map(":)"->3,":D"->4,":("->1,">:O"->0,":'("->0)
  private var pipeline: StanfordCoreNLP = null;

  private def getPipeLine: StanfordCoreNLP = {
    if (null == pipeline) {
      val props = new Properties()
      props.setProperty("annotators", "tokenize, ssplit, parse, sentiment")
      pipeline = new StanfordCoreNLP(props)
    }
    pipeline
  }

  private def getSentiment( msg: String): Int = {
    val pipe= getPipeLine
    val annotation = pipe.process(msg)
    val sentences = annotation.get(classOf[CoreAnnotations.SentencesAnnotation])
    var maxSentSize = 0
    var sentiment:Float = 0

    for (i <- 0 to sentences.size() - 1) {
      val sentence = sentences.get(i)
      if (emoticonsMap.contains(sentence.toString)){
        sentiment +=emoticonsMap(sentence.toString)
      }
      else {

        val tree = sentence.get(classOf[SentimentCoreAnnotations.SentimentAnnotatedTree])
        val sc = RNNCoreAnnotations.getPredictedClass(tree)

        sentiment += sentimentCorrector(sentence.toString, sc)
        log.info(s"${sentence.toString} => $sc + where as sentiment $sentiment")
      }
    }

    math.round(sentiment/sentences.size())
  }


  def analyze(rdd: RDD[TagMessage], onColumn: String): RDD[(String, SentimentIdx)] = {
    val sqlContext = SQLContext.getOrCreate(rdd.sparkContext)
    val df = sqlContext.createDataFrame(rdd)
    df.select(col("tagId"), col(onColumn), sentiment(col(onColumn)).as('sentiment)).
      rdd.map(x => (x.getString(0), SentimentIdx(x.getString(1), x.getInt(2))))
  }


  def analyze(rdd: RDD[TagMessage]): RDD[(String, SentimentIdx)] = {

    rdd.map(x => (x.tagId, SentimentIdx(x.message, getSentiment( x.message.trim))))

  }

  def sentimentCorrector(msg:String, sentiment:Int):Int={
    if ((msg.toLowerCase.contains("don't") ||msg.toLowerCase.contains("do not")||msg.toLowerCase.contains("didn't")||msg.toLowerCase.contains("did not")) && sentiment<=2) sentiment
    else if ((msg.toLowerCase.contains("like") ||msg.toLowerCase.contains("love") ) && sentiment<=2) 3
    else sentiment
  }


}

